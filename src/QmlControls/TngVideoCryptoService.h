#pragma once

#include <QtCore/QByteArray>
#include <QtCore/QMutex>
#include <QtCore/QString>

#include "TngCryptoEngine.h"

class TngVideoCryptoService
{
public:
    enum class SpeedMode {
        Normal,
        High,
    };

    static TngVideoCryptoService &instance();

    bool acquire(SpeedMode mode, QString *error = nullptr);
    void release();

    QByteArray encryptChunk(const QByteArray &plain, SpeedMode mode, QString *error = nullptr);
    QByteArray decryptChunk(const QByteArray &cipher, SpeedMode mode, QString *error = nullptr);

private:
    TngVideoCryptoService() = default;
    ~TngVideoCryptoService() = default;

    Q_DISABLE_COPY_MOVE(TngVideoCryptoService)

    static QByteArray _fingerprint(const TngCryptoConfig &config);

    QMutex _mutex;
    TngCryptoEngine _engine;
    QByteArray _configFingerprint;
    int _users = 0;
};
