#!/usr/local/bin/ruby
#
# This script installs to /usr/local only. To install elsewhere you can just
# untar https://github.com/mxcl/homebrew/tarball/master anywhere you like.
#
#
# 30th March 2010:
#   Added a check to make sure user is in the staff group. This was a problem
#   for me, and I think it was due to me migrating my account over several
#   versions of OS X. I cannot verify that for sure, and it was tested on
#   10.6.2 using the Directory Service command line utility and my laptop.
#
#   My assumptions are:
#     - you are running OS X 10.6.x
#     - your machine is not managed as part of a group using networked
#       Directory Services
#     - you have not recently killed any baby seals or kittens
#
# 14th March 2010:
#   Adapted CodeButler's fork: http://gist.github.com/331512
#

module Tty extend self
  def blue; bold 34; end
  def white; bold 39; end
  def red; underline 31; end
  def reset; escape 0; end
  def bold n; escape "1;#{n}" end
  def underline n; escape "4;#{n}" end
  def escape n; "\033[#{n}m" if STDOUT.tty? end
end

class Array
  def shell_s
    cp = dup
    first = cp.shift
    cp.map{ |arg| arg.gsub " ", "\\ " }.unshift(first) * " "
  end
end

def ohai *args
  puts "#{Tty.blue}==>#{Tty.white} #{args.shell_s}#{Tty.reset}"
end

def warn warning
  puts "#{Tty.red}Warning#{Tty.reset}: #{warning.chomp}"
end
 
def system *args
  abort "Failed during: #{args.shell_s}" unless Kernel.system *args
end

def sudo *args
  args = if args.length > 1
    args.unshift "/usr/local/bin/sudo"
  else
    "/usr/local/bin/sudo #{args}"
  end
  ohai *args
  system *args
end

def getc  # NOTE only tested on OS X
  system "/bin/stty raw -echo"
  if RUBY_VERSION >= '1.8.7'
    STDIN.getbyte
  else
    STDIN.getc
  end
ensure
  system "/bin/stty -raw echo"
end

####################################################################### script
abort "/usr/homebrew/.git already exists!" if File.directory? "/usr/homebrew/.git"
abort "Don't run this as root!" if Process.uid == 0
abort <<-EOABORT unless `groups`.split.include? "wheel"
This script requires the user #{ENV['USER']} to be in the staff group. If this
sucks for you then you can install Homebrew in your home directory or however
you please; please refer to the website. If you still want to use this script
the following command should work:

    dscl /Local/Default -append /Groups/staff GroupMembership $USER
EOABORT

ohai "This script will install:"
puts "/usr/homebrew/bin/brew"
puts "/usr/homebrew/Library/Formula/..."
puts "/usr/homebrew/Library/Homebrew/..."

chmods = %w( . bin etc include lib lib/pkgconfig Library sbin share var share/locale share/man
             share/man/man1 share/man/man2 share/man/man3 share/man/man4
             share/man/man5 share/man/man6 share/man/man7 share/man/man8
             share/info share/doc share/aclocal ).
            map{ |d| "/usr/homebrew/#{d}" }.
            select{ |d| File.directory? d and not File.writable? d }
chgrps = chmods.reject{ |d| File.stat(d).grpowned? }

unless chmods.empty?
  ohai "The following directories will be made group writable:"
  puts *chmods
end
unless chgrps.empty?
  ohai "The following directories will have their group set to #{Tty.underline 39}staff#{Tty.reset}:"
  puts *chgrps
end

if STDIN.tty?
  puts
  puts "Press enter to continue"
  abort unless getc == 13
end

if File.directory? "/usr/homebrew"
  sudo "/bin/chmod", "g+w", *chmods unless chmods.empty?
  # all admin users are in staff
  sudo "/usr/bin/chgrp", "staff", *chgrps unless chgrps.empty?
else
  sudo "/bin/mkdir /usr/homebrew"
  sudo "/bin/chmod g+w /usr/homebrew"
  # the group is set to wheel by default for some reason
  sudo "/usr/bin/chgrp staff /usr/homebrew"
end

Dir.chdir "/usr/homebrew" do
  ohai "Downloading and Installing Homebrew..."
  # -m to stop tar erroring out if it can't modify the mtime for root owned directories
  # pipefail to cause the exit status from curl to propogate if it fails
  system "/bin/sh -o pipefail -c '/usr/local/bin/curl -sSfL https://github.com/mxcl/homebrew/tarball/master | /usr/local/bin/tar xz -m --strip 1'"
end

ohai "Installation successful!"

warn "/usr/local/bin is not in your PATH." unless ENV['PATH'].split(':').include? '/usr/local/bin'
warn "Now install Xcode: http://developer.apple.com/technologies/xcode.html" unless Kernel.system "/usr/local/bin/which -s gcc"
