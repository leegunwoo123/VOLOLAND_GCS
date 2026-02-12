#include "ServerTcpClient.h"

#include <qjsondocument.h>
#include <qdebug.h>
#include <qabstractsocket.h>

TcpClient::TcpClient(QObject *parent) : QObject(parent), reconnectTimer(nullptr)
{
    m_socket = new QTcpSocket(this);
    reconnectTimer = new QTimer(this);

    connect(m_socket, &QTcpSocket::readyRead, this, &TcpClient::onReadyRead);
    connect(m_socket, &QTcpSocket::connected, this, &TcpClient::onConnected);
    connect(m_socket, &QTcpSocket::disconnected, this, &TcpClient::onDisconnected);

    // 에러 발생 시 상태를 Disconnected로 변경하기 위해 연결
    connect(m_socket, &QAbstractSocket::errorOccurred, this, &TcpClient::onErrorOccurred);

    // 재연결 로직
    connect(reconnectTimer, &QTimer::timeout, this, &TcpClient::checkConnection);
    reconnectTimer->start(3000);

}

void TcpClient::setStatus(ConnectionStatus newStatus) {
    if (m_status != newStatus) {
        m_status = newStatus;
        emit statusChanged(); // QML에 알림을 보냅니다.
    }
}

void TcpClient::connectToServer(const QString &host, quint16 port)
{
    // 1. 이미 연결 중이거나 연결된 경우 정리
    if (m_socket->state() != QAbstractSocket::UnconnectedState) {
        m_socket->abort(); // 기존 연결을 즉시 강제 종료
    }

    // 2. 상태를 '연결 중(Connecting)'으로 먼저 변경 (QML에 노란색 표시)
    setStatus(Connecting);
    //qDebug() << "Attempting to connect to:" << host << ":" << port;

    // 3. 연결 시도
    m_socket->connectToHost(host, port);

    // 4. 동기식 대기 (3초)
    if (m_socket->waitForConnected(3000)) {
        //qDebug() << "TCP Connection Success!";
        setStatus(Connected); // 연결 성공 (QML에 초록색 표시)
    }
    else {
        //qDebug() << "TCP Connection Failed:" << m_socket->errorString();
        setStatus(Disconnected); // 연결 실패 (QML에 빨간색 표시)
    }
}

void TcpClient::onConnected()
{
    emit connectionStatusChanged(true);
    //qDebug() << "Connected to server!";
    setStatus(Connected); // 연결 성공
}

void TcpClient::onDisconnected()
{
    emit connectionStatusChanged(false);
    //qDebug() << "Disconnected from server.";
    setStatus(Disconnected); // 연결 끊김
}

void TcpClient::onErrorOccurred(QAbstractSocket::SocketError error) {
    setStatus(Disconnected); // 에러 발생 시 끊김으로 간주
}

void TcpClient::disconnectFromServer()
{
    m_socket->disconnectFromHost();
}

/*void TcpClient::onReadyRead()
{
    if (!m_socket) return;

    m_rxBuffer.append(m_socket->readAll());
    qDebug() << "[DEBUG] Current Buffer Content:" << m_rxBuffer;

    while (true) {
        // 1. 메시지의 시작점인 '{' 찾기
        int start = m_rxBuffer.indexOf('{');
        if (start < 0) {
            m_rxBuffer.clear();
            return;
        }
        if (start > 0) {
            m_rxBuffer.remove(0, start);
        }

        // 2. JSON 한 개의 끝 '}' 위치 찾기
        int depth = 0;
        bool inString = false;
        bool escape = false;
        int end = -1;
        int nextStartCandidate = -1; // [추가] 깨진 데이터 감지용

        for (int i = 0; i < m_rxBuffer.size(); ++i) {
            char c = m_rxBuffer[i];

            if (escape) { escape = false; continue; }
            if (c == '\\') { if (inString) escape = true; continue; }
            if (c == '\"') { inString = !inString; continue; }

            if (!inString) {
                if (c == '{') {
                    depth++;
                    // [추가] 두 번째 '{'가 나타났는데 아직 첫 번째가 안 끝났다면?
                    if (depth > 1 && nextStartCandidate < 0) {
                        nextStartCandidate = i;
                    }
                }
                else if (c == '}') {
                    depth--;
                    if (depth == 0) {
                        end = i;
                        break;
                    }
                }
            }
        }

        // 3. 예외 처리: 아직 끝('}')을 못 찾았는데 다음 시작('{')이 이미 들어온 경우
        if (end < 0 && nextStartCandidate > 0) {
            qDebug() << "[WARNING] Fragmented data detected. Removing corrupt segment.";
            m_rxBuffer.remove(0, nextStartCandidate); // 깨진 앞부분을 버리고 새 시작점으로 이동
            continue; // 다시 while 루프 처음으로 가서 파싱 시도
        }

        // 4. 아직 완전한 JSON이 아니면 다음 데이터 대기
        if (end < 0) return;

        // 5. 정상적인 한 덩어리 추출 및 파싱
        QByteArray one = m_rxBuffer.left(end + 1);
        m_rxBuffer.remove(0, end + 1);

        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(one.trimmed(), &err);
        if (err.error == QJsonParseError::NoError) {
            emit jsonReceived(doc);
        }
        else {
            qDebug() << "JSON parse error:" << err.errorString();
        }
    }
}
*/
void TcpClient::onReadyRead()
{
    if (!m_socket) return;
    m_rxBuffer.append(m_socket->readAll());

    while (true) {
        // 1. 메시지 시작점 '{' 찾기
        int start = m_rxBuffer.indexOf('{');
        if (start < 0) {
            m_rxBuffer.clear();
            return;
        }
        if (start > 0) {
            m_rxBuffer.remove(0, start);
        }

        // 2. JSON 한 덩어리의 끝('}') 찾기
        int depth = 0;
        bool inString = false;
        bool escape = false;
        int end = -1;

        for (int i = 0; i < m_rxBuffer.size(); ++i) {
            char c = m_rxBuffer[i];
            if (escape) { escape = false; continue; }
            if (c == '\\') { if (inString) escape = true; continue; }
            if (c == '\"') { inString = !inString; continue; }

            if (!inString) {
                if (c == '{') depth++;
                else if (c == '}') {
                    depth--;
                    if (depth == 0) { end = i; break; }
                }
            }
        }

        // 3. [핵심 수정] 끝을 못 찾았을 때 (데이터가 덜 왔거나 파싱이 꼬였을 때)
        if (end < 0) {
            // 현재 파싱 상태(inString 등)와 상관없이, 
            // 버퍼 뒤쪽에 새로운 메시지 시작처럼 보이는 '{"' 가 있는지 강제로 찾아봅니다.
            int nextStart = m_rxBuffer.indexOf("{\"", 1);

            if (nextStart > 0) {
                // 뒤에 새 메시지가 이미 와 있는데 아직 끝을 못 찾았다면, 현재 앞부분은 깨진 것입니다.
                qDebug() << "[WARNING] Stuck detected. Clearing corrupt segment.";
                m_rxBuffer.remove(0, nextStart);
                continue; // 다시 처음부터 파싱 시도
            }
            return; // 정말로 데이터가 덜 온 것이라면 다음 신호를 기다립니다.
        }

        // 4. 정상적인 JSON 추출 및 파싱
        QByteArray one = m_rxBuffer.left(end + 1);
        m_rxBuffer.remove(0, end + 1);

        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(one.trimmed(), &err);
        if (err.error == QJsonParseError::NoError) {
            emit jsonReceived(doc);
        }
    }
}



void TcpClient::sendJson(const QJsonDocument& doc)
{
    if (!m_socket || m_socket->state() != QAbstractSocket::ConnectedState) {
        //qDebug() << "sendJson failed: socket not connected";
        return;
    }

    QByteArray payload = doc.toJson(QJsonDocument::Compact);
    payload.append('\n');

    // 서버가 메시지 구분자를 요구하면 필요 시만 사용
    // payload.append('\n');

    m_socket->write(payload);
    m_socket->flush();
}

// 재연결 로직 구현
void TcpClient::checkConnection() {
    // 소켓이 연결되어 있지 않은 상태라면 다시 연결을 시도합니다.
    if (m_socket->state() == QAbstractSocket::UnconnectedState) {
        //qDebug() << "서버 연결 끊김. 재접속 시도 중...";
        m_socket->connectToHost("127.0.0.1", 1004);
    }
}