#include "EncryptedMavlinkLink.h"
#include "TngCryptoConfig.h"

EncryptedMavlinkConfiguration::EncryptedMavlinkConfiguration(const QString &name, QObject *parent)
    : LinkConfiguration(name, parent)
{
}

EncryptedMavlinkConfiguration::EncryptedMavlinkConfiguration(const EncryptedMavlinkConfiguration *copy, QObject *parent)
    : LinkConfiguration(copy, parent)
    , _iniPath(copy->_iniPath)
    , _host(copy->_host)
    , _port(copy->_port)
    , _mode(copy->_mode)
{
}

void EncryptedMavlinkConfiguration::copyFrom(const LinkConfiguration *source)
{
    LinkConfiguration::copyFrom(source);
    const auto *src = qobject_cast<const EncryptedMavlinkConfiguration *>(source);
    if (!src) {
        return;
    }
    setIniPath(src->_iniPath);
    setHost(src->_host);
    setPort(src->_port);
    setMode(src->_mode);
}

void EncryptedMavlinkConfiguration::loadSettings(QSettings &settings, const QString &root)
{
    setIniPath(settings.value(root + "/iniPath", _iniPath).toString());
    setHost(settings.value(root + "/host", _host).toString());
    setPort(static_cast<quint16>(settings.value(root + "/port", _port).toUInt()));
    setMode(settings.value(root + "/mode", _mode).toInt());
}

void EncryptedMavlinkConfiguration::saveSettings(QSettings &settings, const QString &root) const
{
    settings.setValue(root + "/iniPath", _iniPath);
    settings.setValue(root + "/host", _host);
    settings.setValue(root + "/port", _port);
    settings.setValue(root + "/mode", _mode);
}

void EncryptedMavlinkConfiguration::setIniPath(const QString &path)
{
    if (_iniPath == path) {
        return;
    }
    _iniPath = path;
    emit iniPathChanged();
}

void EncryptedMavlinkConfiguration::setHost(const QString &host)
{
    if (_host == host) {
        return;
    }
    _host = host;
    emit hostChanged();
}

void EncryptedMavlinkConfiguration::setPort(quint16 port)
{
    if (_port == port) {
        return;
    }
    _port = port;
    emit portChanged();
}

void EncryptedMavlinkConfiguration::setMode(int mode)
{
    const int clamped = (mode == 1) ? 1 : 0;
    if (_mode == clamped) {
        return;
    }
    _mode = clamped;
    emit modeChanged();
}

/*===========================================================================*/

EncryptedMavlinkLink::EncryptedMavlinkLink(SharedLinkConfigurationPtr &config, QObject *parent)
    : LinkInterface(config, parent)
    , _cfg(qobject_cast<EncryptedMavlinkConfiguration *>(config.get()))
{
    connect(&_pipe, &EncryptedTcpPipe::connected, this, &EncryptedMavlinkLink::_onPipeConnected);
    connect(&_pipe, &EncryptedTcpPipe::disconnected, this, &EncryptedMavlinkLink::_onPipeDisconnected);
    connect(&_pipe, &EncryptedTcpPipe::plainReceived, this, &EncryptedMavlinkLink::_onPlainReceived);
    // 개별 오류는 CryptoLinkMonitor(툴바 알림)로만 모으고, 링크가 실제로 중지된 경우에만 QGC 오류를 올린다.
    connect(&_pipe, &EncryptedTcpPipe::suspended, this, &EncryptedMavlinkLink::_onPipeSuspended);
}

EncryptedMavlinkLink::~EncryptedMavlinkLink()
{
    _connected = false;
    _pipe.stop();
}

bool EncryptedMavlinkLink::isConnected() const
{
    return _connected;
}

bool EncryptedMavlinkLink::_connect()
{
    TngCryptoConfig cryptoCfg;
    QString err;
    const QString iniPath = _cfg ? _cfg->iniPath() : QString();
    if (!TngCryptoConfig::load(iniPath, cryptoCfg, &err)) {
        emit communicationError(tr("Vololand"), err);
        return false;
    }

    // TCP 접속 정보는 링크 설정(Comm Links UI)에서 주입. ini의 [crypto]만 사용.
    if (_cfg) {
        cryptoCfg.host = _cfg->host();
        cryptoCfg.port = _cfg->port();
        cryptoCfg.tcpMode = (_cfg->mode() == 1) ? TngCryptoConfig::TcpMode::Server
                                                : TngCryptoConfig::TcpMode::Client;
    }
    _secure = cryptoCfg.enabled;

    if (!_pipe.start(cryptoCfg, &err)) {
        emit communicationError(tr("Vololand"), err);
        return false;
    }

    // TCP connect는 동기일 수 있음. 이미 세션이 열렸으면 connected 처리.
    if (_pipe.isConnected()) {
        _onPipeConnected();
    }
    return true;
}

void EncryptedMavlinkLink::disconnect()
{
    _connected = false;
    _pipe.stop();
    // LinkManager 수동 disconnect 경로
    emit disconnected();
}

void EncryptedMavlinkLink::_writeBytes(const QByteArray &bytes)
{
    _pipe.sendPlain(bytes);
    emit bytesSent(this, bytes);
}

void EncryptedMavlinkLink::_onPipeDisconnected()
{
    if (!_connected) {
        return;
    }
    _connected = false;

    // LinkManager::disconnected 를 보내지 않는다.
    // 보내면 링크가 제거되어 TcpClient 재연결이 불가능해진다.
}

void EncryptedMavlinkLink::_onPipeConnected()
{
    if (_connected) {
        return;
    }
    _connected = true;
    emit connected();
}

void EncryptedMavlinkLink::_onPlainReceived(const QByteArray &plain)
{
    emit bytesReceived(this, plain);
}

void EncryptedMavlinkLink::_onPipeSuspended(const QString &reason)
{
    emit communicationError(tr("Vololand"), reason);
}
