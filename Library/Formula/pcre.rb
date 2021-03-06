require 'formula'

class Pcre <Formula
  url 'http://ftp.exim.llorien.org/pcre/pcre-8.12.tar.bz2'
  homepage 'http://www.pcre.org/'
  md5 'f14a9fef3c92f3fc6c5ac92d7a2c7eb3'

  def options
    [["--universal", "Build a universal binary."]]
  end

  def install
    fails_with_llvm "Bus error in ld on SL 10.6.4"
    ENV.universal_binary if ARGV.include? "--universal"

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-utf8",
                          "--enable-unicode-properties",
                          "--enable-pcregrep-libz",
                          "--enable-pcregrep-libbz2"
    system "make test"
    system "make install"
  end
end
