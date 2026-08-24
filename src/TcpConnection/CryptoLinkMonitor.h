#pragma once

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QVariantList>

/// 암호화 링크(EncryptedTcpPipe)의 오류 이력과 수신 통계를 모아 QML에 노출한다.
/// 오류마다 모달 다이얼로그를 띄우는 대신 툴바 아이콘 + 목록 팝업으로 확인시키는 것이 목적이며,
/// 차단/재시도 정책은 EncryptedTcpPipe 가 결정하고 그 결과만 여기에 기록된다.
class CryptoLinkMonitor : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList entries          READ entries          NOTIFY entriesChanged)
    Q_PROPERTY(int          unreadCount      READ unreadCount      NOTIFY entriesChanged)
    Q_PROPERTY(int          worstUnreadLevel READ worstUnreadLevel NOTIFY entriesChanged)
    Q_PROPERTY(bool         suspended        READ suspended        NOTIFY statsChanged)
    Q_PROPERTY(bool         linkConnected    READ linkConnected    NOTIFY statsChanged)

public:
    enum Level {
        Info    = 0,
        Warning = 1,
        Error   = 2
    };
    Q_ENUM(Level)

    explicit CryptoLinkMonitor(QObject *parent = nullptr);

    static CryptoLinkMonitor *instance();
    static void registerQmlTypes();

    QVariantList entries()      const { return _entries; }
    int          unreadCount()  const { return _unreadCount; }
    int          worstUnreadLevel() const { return _worstUnreadLevel; }
    bool         suspended()    const { return _suspended; }
    bool         linkConnected()const { return _linkConnected; }

    Q_INVOKABLE void clear();
    Q_INVOKABLE void markAllRead();

    /// 임계 초과로 중지된 파이프에 재시작을 요청한다. EncryptedTcpPipe 가 resumeRequested 를 구독한다.
    Q_INVOKABLE void requestResume();

public slots:
    void reportEvent(int level, const QString &source, const QString &message);
    void noteConnected(bool connected);
    void noteSuspended(bool suspended);

signals:
    void entriesChanged();
    void statsChanged();
    void resumeRequested();

private:
    /// 같은 오류가 초당 수십 건 반복돼도 QML 바인딩이 매번 깨지 않도록 통지를 묶어서 낸다.
    void _scheduleNotify();
    void _notifyNow();

    static constexpr int kMaxEntries  = 200;
    static constexpr int kNotifyDelayMs = 400;

    QVariantList _entries;          // [{ time, level, levelText, source, message, count }, ...] 최신이 앞
    int  _unreadCount      = 0;
    int  _worstUnreadLevel = -1;
    bool _suspended        = false;
    bool _linkConnected    = false;
    bool _notifyPending    = false;
};
