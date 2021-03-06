# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools desktop gnome2-utils xdg-utils git-r3

DESCRIPTION="Electronic Identity Card middleware supplied by the Belgian Federal Government"
HOMEPAGE="https://eid.belgium.be"
EGIT_REPO_URI="https://github.com/Fedict/${PN}.git"

LICENSE="LGPL-3"
SLOT="0"
IUSE="+dialogs +gtk +p11v220 p11-kit"

RDEPEND=">=sys-apps/pcsc-lite-1.2.9
	gtk? (
		x11-libs/gdk-pixbuf[jpeg]
		x11-libs/gtk+:3
		dev-libs/libxml2
		net-misc/curl[ssl]
		net-libs/libproxy
		!app-misc/eid-viewer-bin
	)
	p11-kit? ( app-crypt/p11-kit )"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

REQUIRED_USE="dialogs? ( gtk )"

src_prepare() {
	default

	sed -i -e 's:/beid/rsaref220:/rsaref220:' configure.ac || die
	sed -i -e 's:/beid::' cardcomm/pkcs11/src/libbeidpkcs11.pc.in || die

	# legacy xpi module : we don't want it anymore
	sed -i -e '/SUBDIRS/ s:plugins_tools/xpi ::' Makefile.am || die
	sed -i -e '/plugins_tools\/xpi/ d' configure.ac || die

	# hardcoded lsb_info
	sed -i \
		-e "s:get_lsb_info('i'):strdup(_(\"Gentoo\")):" \
		-e "s:get_lsb_info('r'):strdup(_(\"n/a\")):" \
		-e "s:get_lsb_info('c'):strdup(_(\"n/a\")):" \
		plugins_tools/aboutmw/gtk/about-main.c || die

	# Fix libdir for pkcs11_manifestdir
	sed -i \
		-e "/pkcs11_manifestdir/ s:prefix)/lib:libdir):" \
		cardcomm/pkcs11/src/Makefile.am || die

	# See bug #732994
	sed -i \
		-e '/LDFLAGS="/ s:$CPPFLAGS:$LDFLAGS:' \
		configure.ac || die

	eautoreconf
}

src_configure() {
	econf \
		$(use_enable dialogs) \
		$(use_enable p11v220) \
		$(use_enable p11-kit p11kit) \
		$(use_with gtk gtkvers 'detect') \
		--with-gnu-ld \
		--disable-static
}

src_install() {
	default
	rm -r "${ED}"/usr/$(get_libdir)/*.la || die
	if use gtk; then
		domenu plugins_tools/eid-viewer/eid-viewer.desktop
		doicon plugins_tools/eid-viewer/gtk/eid-viewer.png
	fi
}

pkg_postinst() {
	if use gtk; then
		gnome2_schemas_update
		xdg_desktop_database_update
		xdg_icon_cache_update
	fi
}

pkg_postrm() {
	if use gtk; then
		gnome2_schemas_update
		xdg_desktop_database_update
		xdg_icon_cache_update
	fi
}
