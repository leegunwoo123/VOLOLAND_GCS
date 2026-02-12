#include "DroneManager.h"
#include "DroneModel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <qdatetime.h>

// 생성자는 헤더에서 인라인으로 정의했으므로 여기서는 생략하거나 
// 헤더와 맞춰서 한 번 더 정의할 수 있습니다. 
// 하지만 헤더에 이미 (DroneModel *model...) : m_droneModel(model) {} 이 있다면 생략해도 됩니다.

void DroneManager::processIncomingData(const QJsonDocument& jsonDoc)
{
    //// 1. 데이터가 유효한지 확인
    //if (jsonDoc.isNull()) {
    //    return;
    //}

    //// 2. [HelloWorld 확인용] 받은 데이터를 통째로 문자열로 변환하여 모델에 전달
    //// QML 화면의 디버그 창에 이 텍스트가 표시됩니다.
    //QString rawString = jsonDoc.toJson(QJsonDocument::Indented);
    //if (m_droneModel) {
    //    m_droneModel->setRecentData(rawString);
    //}

    //// 3. 실제 드론 데이터 파싱 로직 (나중에 확장을 위해 구조 유지)
    //if (!jsonDoc.isObject()) {
    //    return;
    //}

    //QJsonObject root = jsonDoc.object();
    //QString type = root["type"].toString();

    //if (type == "list") {
    //    handleListMessage(root["data"].toArray());
    //}
    //else if (type == "heartbeat") {
    //    handleHeartbeatMessage(root["data"].toObject());
    //}
    if (jsonDoc.isNull()) return;

    // 디버그 표시 유지 OK
    QString rawString = jsonDoc.toJson(QJsonDocument::Indented);
    if (m_droneModel) m_droneModel->setRecentData(rawString);

    if (!jsonDoc.isObject()) return;

    QJsonObject root = jsonDoc.object();
    QString type = root["type"].toString();

    if (type == "list") {
        handleListMessage(root["data"].toArray());

        if (m_droneModel) {          // ✅ 모델이 있을 때만 로드 완료 처리
            m_listLoaded = true;
            m_lastHbMs.clear();
        }
    }
    else if (type == "heartbeat") {
        handleHeartbeatMessage(root["data"].toObject());
    }

}

void DroneManager::handleListMessage(const QJsonArray& dataArray)
{
    //if (!m_droneModel) return;

    //// 새 목록을 받으면 기존 모델을 비움
    //m_droneModel->clearModel();

    //for (int i = 0; i < dataArray.size(); ++i) {
    //    QJsonObject obj = dataArray[i].toObject();

    //    DroneItem item;
    //    item.depth = obj["depth"].toInt();
    //    item.nodeType = obj["nodeType"].toString();
    //    item.groupName = obj["groupName"].toString();
    //    item.deviceName = obj["deviceName"].toString();
    //    item.status = obj["status"].toString();
    //    item.isArmed = obj["isArmed"].toBool();
    //    item.battery = obj["battery"].toInt();
    //    item.flightmode = obj["flightmode"].toString();
    //    item.flighttype = obj["flighttype"].toString();
    //    item.hasError = obj["hasError"].toBool();
    //    item.isExpanded = true;  // 기본값
    //    item.isVisible = true;   // 기본값

    //    m_droneModel->appendDrone(item);
    //}
    if (!m_droneModel) return;

    m_droneModel->clearModel();

    for (int i = 0; i < dataArray.size(); ++i) {
        QJsonObject obj = dataArray[i].toObject();

        DroneItem item;
        item.depth = obj["depth"].toInt();
        item.nodeType = obj["nodeType"].toString();
        item.groupName = obj["groupName"].toString();
        item.deviceName = obj["deviceName"].toString();

        // ✅ 목록은 상태값 없음: 기본값
        item.status = "";
        item.isArmed = false;
        item.battery = 0;
        item.flightmode = "";
        item.flighttype = "";
        item.hasError = false;

        item.isExpanded = true;
        item.isVisible = true;

        m_droneModel->appendDrone(item);
        qDebug() << "APPEND" << item.depth << item.nodeType << item.groupName << item.deviceName;

    }
}

void DroneManager::handleHeartbeatMessage(const QJsonObject& obj)
{
    if (!m_droneModel || !m_listLoaded) return;

    QString name = obj["deviceName"].toString();
    if (name.isEmpty()) return;

    // 1. 수신 시간 갱신 (타임아웃 체크용)
    m_lastHbMs[name] = QDateTime::currentMSecsSinceEpoch();

    // 2. 데이터 보정: status가 비어있으면 "ONLINE"으로 강제 설정
    QJsonObject patched = obj;
    if (patched["status"].toString().isEmpty()) {
        patched["status"] = "ONLINE";
    }

    // 3. 모델 업데이트 (수정됨: obj 대신 patched 전달)
    m_droneModel->updateDrone(name, patched);
}

DroneManager::DroneManager(DroneModel* model, QObject* parent)
    : QObject(parent)
    , m_droneModel(model)
{
    // 3초마다 OFFLINE 판정
    connect(&m_offlineTimer, &QTimer::timeout, this, &DroneManager::markOfflineIfTimeout);
    m_offlineTimer.start(3000);
}

void DroneManager::requestListRefresh()
{
    // 서버 프로토콜에 맞춰 type만 정하면 됨 (예: "list_request")
    QJsonObject req;
    req["type"] = "list_request";  // ← 서버 스펙에 맞게 문자열만 조정


    emit sendJsonRequest(QJsonDocument(req));
}

void DroneManager::markOfflineIfTimeout()
{
    if (!m_listLoaded || !m_droneModel) return;

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();

    for (auto it = m_lastHbMs.begin(); it != m_lastHbMs.end(); ++it) {
        const QString& name = it.key();
        const qint64 lastMs = it.value();

        if (nowMs - lastMs > m_offlineTimeoutMs) {
            // 옵션1: status만 OFFLINE로 변경(나머지 값 유지)
            m_droneModel->setDeviceStatus(name, "OFFLINE");
        }
    }
}
 // json 텍스트 주입
void DroneManager::injectJsonText(const QString& text)
{
    QByteArray buf = text.toUtf8();
    buf = buf.trimmed();
    if (buf.isEmpty()) return;

    // 디버그창에 표시
    if (m_droneModel) {
        m_droneModel->setRecentData(QString("[INJECT]\n") + QString::fromUtf8(buf));
    }

    // 스트림에서 JSON object들을 추출해서 하나씩 처리
    while (true) {
        int start = buf.indexOf('{');
        if (start < 0) return;
        if (start > 0) buf.remove(0, start);

        int depth = 0;
        bool inString = false;
        bool escape = false;
        int end = -1;

        for (int i = 0; i < buf.size(); ++i) {
            char c = buf[i];

            if (escape) { escape = false; continue; }
            if (c == '\\') { if (inString) escape = true; continue; }
            if (c == '"') { inString = !inString; continue; }

            if (!inString) {
                if (c == '{') depth++;
                else if (c == '}') {
                    depth--;
                    if (depth == 0) { end = i; break; }
                }
            }
        }

        if (end < 0) return; // 아직 완전한 JSON이 아님

        QByteArray one = buf.left(end + 1);
        buf.remove(0, end + 1);

        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(one, &err);
        if (err.error != QJsonParseError::NoError) {
            if (m_droneModel) {
                m_droneModel->setRecentData(
                    QString("[INJECT PARSE ERROR] %1\n%2")
                    .arg(err.errorString(), QString::fromUtf8(one))
                );
            }
            continue;
        }

        processIncomingData(doc);
    }
}

