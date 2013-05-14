#!/usr/bin/ruby

class EmulabExport
    
    attr_accessor :identity

    def finalize()
        system("rm -Rf ec2-ami-tools-1.4.0.9 > /dev/null 2>&1")
        system("rm ec2-ami-tools.zip > /dev/null 2>&1")
    end

    def create_image()
        raise "Failed fetching ec2-utils" unless
            system("wget http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip")
        raise "Failed unzippinging ec2-utils" unless
            system("unzip ec2-ami-tools.zip")

        $:.unshift(Dir.pwd + "/ec2-ami-tools-1.4.0.9/lib/")
        require 'ec2/platform/current'

        excludes = ['/tmp/image', '/dev', '/media', '/mnt',
            '/proc', '/sys', '/', '/proc/sys/fs/binfmt_misc', '/dev/pts',
            '/var/lib/cloud/sem']
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

    def check_prereqs()
        raise "No unzip found. Please install unzip"
            unless system("command -v unzip >/dev/null 2>&1")
    end

    def get_kernel()
        version = `uname -r`.chomp

        pkernels = []
        pkernels << "/boot/vmlinuz-" + version
        pkernels << "/boot/vmlinuz-" + version + ".img"

        pinitrd = []
        pinitrd << "/boot/initramfs-" + version + ".img"
        pinitrd << "/boot/initrd-" + version
        pinitrd << "/boot/initrd-" + version + ".img"

        kernelfound = false
        pkernels.each do |kernel|
            if File.exists?(kernel)
                kernelfound = true
                raise "Couldn't copy kernel" unless
                    system("cp " + kernel + " kernel")
                break
            end
        end
        raise "Couldn't find kernel" if kernelfound == false

        initrdfound = false
        pinitrd.each do |initrd|
            if File.exists?(initrd)
                initrdfound = true
                raise "Couldn't copy initrd" unless
                    system("cp " + initrd + " initrd")
                break
            end
        end
        raise "Couldn't find initrd" if initrdfound == false

    end


    def get_bootopts()
        raise "Couldn't get bootopts" unless
            system("cat /proc/cmdline > bootopts") 
    end

    def gen_tar()
        raise "Couldn't tar" unless
            system("tar -cvzf emulab.tar.gz kernel initrd " +
                "bootopts -C /tmp/ image 2>&1")
    end

   end


if __FILE__ == $0
    raise 'Must run as root' unless Process.uid == 0

    begin
        ex = EmulabExport.new()
        ex.check_prereqs
        ex.create_image
        ex.get_kernel
        ex.get_bootopts
        ex.gen_tar
    rescue Exception => e
        print "Error while creating an image: \n"
        puts e.message
        print e.backtrace.join("\n")
    ensure
        ex.finalize()        
    end
end


