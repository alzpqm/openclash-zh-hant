include $(TOPDIR)/rules.mk

PKG_NAME:=luci-i18n-openclash-zh-hant
PKG_VERSION:=0.47.156
PKG_RELEASE:=4
PKG_MAINTAINER:=OpenClash 正體中文化維護者
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=OpenClash LuCI 正體中文語言包
	PKGARCH:=all
	DEPENDS:=+luci-app-openclash
endef

define Package/$(PKG_NAME)/description
	OpenClash LuCI 正體中文語言包（zh_Hant）。
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ "$${IPKG_NO_SCRIPT:-0}" = "1" ] && exit 0
[ -n "$${IPKG_INSTROOT:-}" ] && exit 0
[ -x /sbin/uci ] || exit 0
/sbin/uci -q set luci.languages.zh_tw='正體中文' || exit 0
/sbin/uci -q commit luci
exit 0
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	po2lmo $(CURDIR)/../luci-app-openclash/po/zh_Hant/openclash.zh_Hant.po $(PKG_BUILD_DIR)/openclash.zh-tw.lmo
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/openclash.zh-tw.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/openclash.zh-tw.lmo $(1)/usr/lib/lua/luci/i18n/openclash.zh-hant.lmo
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/openclash.zh-tw.lmo $(1)/usr/lib/lua/luci/i18n/openclash.zh_Hant.lmo
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/luci-i18n-openclash-zh-hant $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
