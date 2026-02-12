#ifndef TCPCLIENT_H
#define TCPCLIENT_H

#include <QObject>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonObject>
#include <qtimer.h>

class TcpClient : public QObject
{
    Q_OBJECT
    // 상태가 변하면 statusChanged 신호가 발생하여 QML UI를 자동으로 갱신합니다.
    Q_PROPERTY(int status READ status NOTIFY statusChanged)
public:

    Q_INVOKABLE void sendJson(const QJsonDocument& doc);

    // QML 색상 로직에 맞춘 상태 정의 (0:연결, 1:연결중, 2:끊김)
    enum ConnectionStatus {
        Connected = 0,
        Connecting = 1,
        Disconnected = 2
    };

    explicit TcpClient(QObject *parent = nullptr);
    int status() const { return m_status; }

    // 서버 연결 함수
    void connectToServer(const QString &host, quint16 port);
    void disconnectFromServer();

signals:
    // JSON 데이터가 준비되었을 때 DroneManager에게 보낼 시그널
    void jsonReceived(const QJsonDocument &jsonDoc);
    void connectionStatusChanged(bool connected);
    void statusChanged(); // 상태 변화를 알리는 신호

private slots:
    // 소켓에 데이터가 들어왔을 때 호출될 슬롯
    void onReadyRead();
    void onConnected();
    void onDisconnected();
    void onErrorOccurred(QAbstractSocket::SocketError error);

private:
    QTcpSocket *m_socket;
    QByteArray m_rxBuffer;
    int m_status = Disconnected; // 초기 상태는 연결 끊김
    void setStatus(ConnectionStatus newStatus);
    // 서버 연결 상태 확인
    QTimer* reconnectTimer;
    void checkConnection();
};

#endif
