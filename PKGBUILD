pkgname=shortcut-manager
pkgver=1.0.0
pkgrel=1
pkgdesc="A terminal-based tool to create, edit, and delete .desktop shortcuts"
arch=('x86_64')
url="https://github.com/jebin2/shortcut-manager"
license=('GPL')
depends=('bash' 'gum' 'bat')
source=("https://github.com/jebin2/shortcut-manager/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP') # Replace with real sha256sum or 'SKIP' for testing

package() {
    # Install the script
    install -Dm755 "shortcut-manager-1.0.0/shortcut-manager.sh" "$pkgdir/usr/bin/shortcut-manager"

    # Install the desktop file
    install -Dm644 "shortcut-manager-1.0.0/shortcut-manager.desktop" "$pkgdir/usr/share/applications/shortcut-manager.desktop"
}
