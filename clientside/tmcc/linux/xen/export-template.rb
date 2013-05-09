#!/usr/bin/ruby

class EmulabExport
    
    attr_accessor :identity

    def initialize()
        @target = "~~SERVER~~" + ":" + "~~IN_DIR~~" + "~~IN_FILE~~"
        @user = "~~USER~~"
        @identity = nil
    end

    def finalize()
        system("rm -Rf ec2-ami-tools-1.4.0.9 > /dev/null 2>&1")
        system("rm ec2-ami-tools.zip > /dev/null 2>&1")
    end

    def create_image()
        raise "Failed fetching ec2-utils" unless
            system("wget http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip")
        raise "Failed unzippinging ec2-utils" unless
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

    def check_prereqs()
        raise "No unzip found. Please install unzip" unless system("command -v unzip >/dev/null 2>&1")
    end

    def get_kernel()
        version = `uname -a`
        version = version.split[2]

        if File.exists?("/boot/vmlinuz-" + version) 
            raise "Couldn't copy kernel" unless
                system("cp /boot/vmlinuz-" + version + " kernel")
        end


        if File.exists?("/boot/initramfs-" + version + ".img")
            raise "Couldn't copy initramfs" unless
                system("cp /boot/initramfs-" + version + ".img initrd")
        end
    end


    def get_bootopts()
        raise "Couldn't get bootopts" unless
            system("cat /proc/cmdline > bootopts") 
    end

    def gen_tar()
        raise "Couldn't tar" unless
            system("tar -cvzf emulab.tar.gz kernel initrd bootopts -C /tmp/ image 2>&1")
    end

    #TODO: Perhaps pull this from a specific emulab server, auto generate
    def inject_pubkey()
        f = File.new(File.expand_path("~") + "/.ssh/authorized_keys", "a+")
        f.write("ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyHww/vuwQ4adLRzUCKdP5/DubwWJjg/YcGwumuHB24Y0u53KX0qd3oprntw0o/ngntlKXdmAuQ/9lb74Vqpoy0LFVU7adPhNRj1z6WbvRo4cwt5BUBxWlTLQFKs3118kATAkMSKFZbXs54y7GvyFWPTdrgfquEizSaKaPcT3Un0FjWobmK81B7etfSZaaD8fMyWuUHHKYq67ZKDJUc4URRHLMZRIHk7wzbMBV0MEeR7y3se1vBKQDV4IzsTnQF4Mur0HBBc2Kif9oDFh8pykatslvSSjAc8J/t9Lp1RADxon3LHX7TFbvHEgAt0t9g8udOOtw4vB7t9l2VrgV5ZLuw== jetru@myboss.metadata.utahstud.emulab.net\n")
        f.close
    end

    def push_to_emulab()
        if @identity == nil
            cmd = "scp emulab.tar.gz " + @user + "@" + @target
        else
            cmd = "scp -i " + @identity + " emulab.tar.gz " + @user + "@" + @target
        end
        puts "Transferring tarred file with: " + cmd
        if system(cmd) == false
            puts "scp failed with error code " + $?.to_s
            puts "You might want to rerun the push using a SSH keyfile using -i"
            puts "Also use the -p flag to only attempt the file transfer and no recreate the image"
        end
    end
end


if __FILE__ == $0
    raise 'Must run as root' unless Process.uid == 0

    ex = EmulabExport.new()
    pushonly = false


    require 'getoptlong'
    #Parse options
    opts = GetoptLong.new(
        ['--identity', '-i', GetoptLong::REQUIRED_ARGUMENT],
        ['--push-only', '-p', GetoptLong::NO_ARGUMENT]
    )

    opts.each do |opt, arg|
        case opt
            when '--identity'
                ex.identity = arg
            when '--push-only'
                pushonly = true
        end
    end
            

    begin
        if pushonly == false
            ex.check_prereqs
            ex.create_image
            ex.get_kernel
            ex.get_bootopts
            ex.gen_tar
        end
        ex.push_to_emulab
    rescue Exception => e
        print "Error while creating an image: \n"
        puts e.message
        print e.backtrace.join("\n")
    ensure
        ex.finalize()        
    end
end


