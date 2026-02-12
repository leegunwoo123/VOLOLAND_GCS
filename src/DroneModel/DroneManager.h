#ifndef DRONEMANAGER_H
#define DRONEMANAGER_H

#include <QObject>
#include <QJsonDocument>
#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qhash.h>
#include <qtimer.h>


// [중요] 전방 선언: DroneModel의 헤더를 include하지 않고 
// "이런 클래스가 있다"라고만 알려줍니다. 순환 참조를 막는 핵심입니다.
class DroneModel;

class DroneManager : public QObject
{
    Q_OBJECT

public:
    // 생성자에서 DroneModel의 주소를 받습니다.
    //explicit DroneManager(DroneModel* model, QObject* parent = nullptr)
    //    : QObject(parent), m_droneModel(model) {
    //}
    explicit DroneManager(DroneModel* model, QObject* parent = nullptr);
    // (정책A) 목록 초기화 + 목록 재요청 버튼에서 호출할 용도
    Q_INVOKABLE void requestListRefresh();

    // json 텍스트 주입
    Q_INVOKABLE void injectJsonText(const QString& text);

public slots:
    // TcpClient의 신호를 받아 처리할 슬롯입니다.
    void processIncomingData(const QJsonDocument& jsonDoc);

signals:
    // DroneManager가 “목록 요청”을 만들면, TcpClient가 실제 전송하도록 넘김(느슨한 결합)
    void sendJsonRequest(const QJsonDocument& doc);

private:
    // 나중에 파싱 로직을 넣을 함수들입니다. (지금은 선언만 둡니다)
    void handleListMessage(const QJsonArray& dataArray);
    void handleHeartbeatMessage(const QJsonObject& obj);

    void markOfflineIfTimeout(); // 5초 타임아웃 체크

private:
    DroneModel* m_droneModel = nullptr;

    bool m_listLoaded = false;                 // 목록 수신 완료 여부(목록 전 heartbeat 무시)
    QHash<QString, qint64> m_lastHbMs;         // deviceName -> 마지막 heartbeat 수신(ms)
    QTimer m_offlineTimer;                     // 1초마다 timeout 체크
    const qint64 m_offlineTimeoutMs = 5000;

};

#endif