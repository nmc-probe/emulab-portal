#!/usr/bin/ruby

class EmulabExport

    def finalize()
        system("rm -Rf ec2-ami-tools-1.4.0.9")
        system("rm ec2-ami-tools.zip")
    end

    def create_image()
        raise 'Must run as root' unless Process.uid == 0

        ObjectSpace.define_finalizer(self, self.method(:finalize))

        raise "Failed fetching ec2-utils" unless
            system("wget http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip")
        raise "Failed untaring ec2-utils" unless
            system("unzip ec2-ami-tools.zip")

        $: << Dir.pwd + "/ec2-ami-tools-1.4.0.9/lib/"
        require 'ec2/platform/current'

        excludes = ['/tmp/image', '/dev', '/media', '/mnt', '/proc', '/sys', '/', '/proc/sys/fs/binfmt_misc', '/dev/pts']
        image = EC2::Platform::Current::Image.new("/",
                                                "/tmp/image",
                                                10* 1024,
                                                excludes,
                                                [],
                                                true,
                                                nil,
                                                true)
        image.make
    end

    def get_kernel()
        version_crap = `uname -a`
        version = version_crap.split[2]

        if File.exists?("/boot/vmlinuz-" + version)
            system("cp /boot/vmlinuz-" + version + " kernel")
        end


        if File.exists?("/boot/initramfs-" + version + ".img")
            system("cp /boot/initramfs-" + version + ".img initrd")
        end
    end


    def get_bootopts()
        system("cat /proc/cmdline > bootopts")
    end

    def gen_tar()
        system("tar -cvzf emulab.tar.gz /tmp/image kernel initrd bootopts")

    end
    def inject_pubkey()
        f = File.new(File.expand_path("~") + "/.ssh/authorized_keys", "a+")
        f.write("ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyHww/vuwQ4adLRzUCKdP5/DubwWJjg/YcGwumuHB24Y0u53KX0qd3oprntw0o/ngntlKXdmAuQ/9lb74Vqpoy0LFVU7adPhNRj1z6WbvRo4cwt5BUBxWlTLQFKs3118kATAkMSKFZbXs54y7GvyFWPTdrgfquEizSaKaPcT3Un0FjWobmK81B7etfSZaaD8fMyWuUHHKYq67ZKDJUc4URRHLMZR
IHk7wzbMBV0MEeR7y3se1vBKQDV4IzsTnQF4Mur0HBBc2Kif9oDFh8pykatslvSSjAc8J/t9Lp1RADxon3LHX7TFbvHEgAt0t9g8udOOtw4vB7t9l2VrgV5ZLuw== jetru@myboss.metadata.utahstud.emulab.net\n")
        f.close
    end
end


if __FILE__ == $0
    ex = EmulabExport.new()
    ex.create_image
    ex.get_kernel
    ex.get_bootopts
    ex.gen_tar
    ex.inject_pubkey
end
