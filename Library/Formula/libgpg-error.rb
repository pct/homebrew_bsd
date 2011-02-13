require 'formula'

class LibgpgError <Formula
  url 'http://anduin.linuxfromscratch.org/sources/BLFS/svn/l/libgpg-error-1.10.tar.bz2'
  homepage 'http://www.gnupg.org/'
  sha1 '95b324359627fbcb762487ab6091afbe59823b29'

  def install
    ENV.j1
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end
end
