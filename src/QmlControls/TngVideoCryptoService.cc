#include "TngVideoCryptoService.h"

#include "QGCLoggingCategory.h"
#include "TngCryptoConfig.h"
#include "VideoEndpointSettings.h"

#include <QtCore/QMutexLocker>

QGC_LOGGING_CATEGORY(TngVideoCryptoServiceLog, "qgc.videocrypto.service")

TngVideoCryptoService &TngVideoCryptoService::instance()
{
    static TngVideoCryptoService service;
    return service;
}

QByteArray TngVideoCryptoService::_fingerprint(const TngCryptoConfig &config)
{
    QByteArray fp;
    fp += QByteArray::number(config.alg);
    fp += '|';
    fp += QByteArray::number(config.mode);
    fp += '|';
    fp += QByteArray::number(static_cast<int>(config.keySource));
    fp += '|';
    fp += QByteArray::number(config.keyIndex);
    fp += '|';
    fp += config.key.toHex();
    fp += '|';
    fp += config.iv.toHex();
    fp += '|';
    fp += config.sysUnique.toUtf8();
    fp += '|';
    fp += config.packageId.toUtf8();
    fp += '|';
    fp += config.keystorePath.toUtf8();
    return fp;
}

bool TngVideoCryptoService::acquire(SpeedMode mode, QString *error)
{
    QMutexLocker locker(&_mutex);

    VideoEndpointSettings::ensureCryptoSection(VideoEndpointSettings::resolveIniPath());

    TngCryptoConfig config;
    if (!TngCryptoConfig::load(VideoEndpointSettings::resolveIniPath(), config, error)) {
        return false;
    }

    // [crypto].enabled=false 면 엔진 초기화 거부(재생 경로 on/off도 동일 플래그).
    if (!config.enabled) {
        if (error) {
            *error = QStringLiteral("video crypto disabled in video_endpoints.ini [crypto]");
        }
        return false;
    }

    // video_endpoints.ini 의 [crypto] 는 alg/mode/key/iv/speed_mode 등 세션 파라미터만 담당한다.
    // 코어 identity 는 프로세스 전역이므로 crypto.ini 값을 채택한다.
    QString identityError;
    if (!TngCryptoConfig::applyGlobalIdentity(config, &identityError)) {
        qCWarning(TngVideoCryptoServiceLog)
            << "crypto.ini load failed, keeping video-local identity:" << identityError;
    }

    config.frameType = TngCryptoConfig::FrameType::MavlinkFixedIv;
    config.ivMode = TngCryptoConfig::IvMode::Fixed;

    const QByteArray fp = _fingerprint(config);
    const bool needInit = (_users == 0) || (_configFingerprint != fp);
    if (needInit) {
        if (_users > 0) {
            _engine.close();
        }
        if (!_engine.init(config, error)) {
            _configFingerprint.clear();
            return false;
        }
        _configFingerprint = fp;
    }

    if (mode == SpeedMode::High && !_engine.highSpeedAvailable()) {
        if (error) {
            *error = QStringLiteral("tngcore.dll does not export tngEncHs/tngDecHs");
        }
        if (_users == 0) {
            _engine.close();
            _configFingerprint.clear();
        }
        return false;
    }

    ++_users;
    return true;
}

void TngVideoCryptoService::release()
{
    QMutexLocker locker(&_mutex);
    if (_users <= 0) {
        return;
    }

    if (--_users == 0) {
        _engine.close();
        _configFingerprint.clear();
    }
}

QByteArray TngVideoCryptoService::encryptChunk(const QByteArray &plain, SpeedMode mode, QString *error)
{
    QMutexLocker locker(&_mutex);
    if (_users <= 0) {
        if (error) {
            *error = QStringLiteral("video crypto service is not acquired");
        }
        return {};
    }

    return mode == SpeedMode::High
               ? _engine.encryptFixedIvHighSpeedMessage(plain, error)
               : _engine.encryptFixedIvMessage(plain, error);
}

QByteArray TngVideoCryptoService::decryptChunk(const QByteArray &cipher, SpeedMode mode, QString *error)
{
    QMutexLocker locker(&_mutex);
    if (_users <= 0) {
        if (error) {
            *error = QStringLiteral("video crypto service is not acquired");
        }
        return {};
    }

    return mode == SpeedMode::High
               ? _engine.decryptFixedIvHighSpeedMessage(cipher, error)
               : _engine.decryptFixedIvMessage(cipher, error);
}
