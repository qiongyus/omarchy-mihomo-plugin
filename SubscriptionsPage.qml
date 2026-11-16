import QtQuick
import QtQuick.Controls
import qs.Ui
import qs.Commons

// Subscriptions = proxy-providers (HTTP/File) with usage, expiry, and manual fetch.
Item {
  id: root

  property var svc: null
  property color fg: Color.popups.text
  property string fontFamily: Style.font.family

  function fmtUpdated(stamp) {
    var text = String(stamp || "")
    if (text === "" || text.indexOf("0001-01-01") === 0)
      return svc ? svc.t("neverFetched") : "Never fetched"
    var parsed = new Date(text)
    if (isNaN(parsed.getTime())) return text
    return Qt.formatDateTime(parsed, "yyyy-MM-dd hh:mm")
  }

  function fmtMeta(item) {
    if (!svc || !item) return ""
    var parts = [svc.t("proxyProviderMeta", item.vehicleType, item.count, fmtUpdated(item.updatedAt))]
    if (item.total > 0) {
      parts.push(svc.t("subUsage", svc.fmtBytes(item.upload + item.download), svc.fmtBytes(item.total)))
    }
    if (item.expire > 0) {
      parts.push(svc.t("subExpire", Qt.formatDateTime(new Date(Number(item.expire) * 1000), "yyyy-MM-dd")))
    }
    return parts.join("  ·  ")
  }

  function scrollBy(delta) {
    var flick = scrollArea.contentItem
    if (!flick) return
    flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height),
                                          flick.contentY + delta))
  }

  PageHeader {
    id: header
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    title: root.svc ? root.svc.t("subscriptionsTitle") : "Subscriptions"
    subtitle: root.svc ? root.svc.t("subscriptionsCount", root.svc.proxyProviders.length) : ""
    foreground: root.fg
    fontFamily: root.fontFamily

    PanelActionButton {
      iconText: "󰑐"
      tooltipText: root.svc ? root.svc.t("refreshSubscriptions") : "Reload subscription status"
      foreground: root.fg
      hoverColor: Color.accent
      fontFamily: root.fontFamily
      enabled: root.svc !== null && !root.svc.providersLoading
      onClicked: root.svc.refreshProviders()
    }
  }

  Rectangle {
    id: headerRule
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: header.bottom
    anchors.topMargin: Style.space(10)
    height: 1
    color: Util.alpha(root.fg, 0.08)
  }

  ScrollView {
    id: scrollArea
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: headerRule.bottom
    anchors.topMargin: Style.space(14)
    anchors.bottom: parent.bottom
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: column.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

    Column {
      id: column
      width: scrollArea.availableWidth
      spacing: Style.space(8)

      Repeater {
        model: root.svc ? root.svc.proxyProviders : []

        Rectangle {
          required property var modelData
          width: column.width
          height: Style.space(48)
          radius: Style.cornerRadius
          color: subMouse.containsMouse ? Util.alpha(root.fg, 0.06) : Util.alpha(root.fg, 0.03)

          MouseArea {
            id: subMouse
            anchors.fill: parent
            hoverEnabled: true
          }

          Column {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(12)
            anchors.right: subUpdate.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: modelData.name
              textFormat: Text.PlainText
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }

            Text {
              width: parent.width
              text: root.fmtMeta(modelData)
              textFormat: Text.PlainText
              color: Util.alpha(root.fg, 0.5)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }
          }

          PanelActionButton {
            id: subUpdate
            anchors.right: parent.right
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            iconText: "󰑐"
            tooltipText: root.svc ? root.svc.t("updateSubscription") : "Fetch this subscription again"
            foreground: root.fg
            hoverColor: Color.accent
            fontFamily: root.fontFamily
            enabled: modelData.vehicleType !== "Inline"
            onClicked: root.svc.updateProxyProvider(modelData.name)
          }
        }
      }

      Text {
        visible: root.svc !== null && root.svc.proxyProviders.length === 0
        width: column.width
        text: root.svc ? root.svc.t("noProxyProviders") : "No proxy providers configured."
        textFormat: Text.PlainText
        color: Util.alpha(root.fg, 0.5)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        renderType: Text.NativeRendering
      }

      Item { width: 1; height: Style.space(4) }
    }
  }
}
