AWSTemplateFormatVersion: "2010-09-09"
Metadata:
    Generator: "former2"
Description: ""
Resources:
    EC2Instance:
        Type: "AWS::EC2::Instance"
        Properties:
            ImageId: "ami-08b5b3a93ed654d19"
            InstanceType: "t2.micro"
            KeyName: "aalimsee-keypair"
            AvailabilityZone: !GetAtt EC2Instance2.AvailabilityZone
            Tenancy: "default"
            SubnetId: "subnet-0a8c0a5fba9c49dd0"
            EbsOptimized: false
            SecurityGroupIds: 
              - "sg-059c183406edb3d90"
            SourceDestCheck: true
            BlockDeviceMappings: 
              - 
                DeviceName: "/dev/xvda"
                Ebs: 
                    Encrypted: false
                    VolumeSize: 8
                    SnapshotId: "snap-0a73fd7b201cb779d"
                    VolumeType: "gp3"
                    DeleteOnTermination: true
            UserData: "CgoKIyEvYmluL2Jhc2gKc3VkbyBkbmYgaW5zdGFsbCBtYXJpYWRiMTA1IC15Cgo="
            Tags: 
              - 
                Key: "Environment"
                Value: "dev"
              - 
                Key: "CreatedBy"
                Value: "Managed by Terraform"
              - 
                Key: "Name"
                Value: "CE9 Project Team XXX"
            HibernationOptions: 
                Configured: false
            EnclaveOptions: 
                Enabled: false

    EC2Instance2:
        Type: "AWS::EC2::Instance"
        Properties:
            ImageId: "ami-08b5b3a93ed654d19"
            InstanceType: "t2.micro"
            KeyName: "aalimsee-keypair"
            AvailabilityZone: !Sub "${AWS::Region}a"
            Tenancy: "default"
            SubnetId: "subnet-0a8c0a5fba9c49dd0"
            EbsOptimized: false
            SecurityGroupIds: 
              - "sg-0dc8a536800dfa832"
            SourceDestCheck: true
            BlockDeviceMappings: 
              - 
                DeviceName: "/dev/xvda"
                Ebs: 
                    Encrypted: false
                    VolumeSize: 8
                    SnapshotId: "snap-0a73fd7b201cb779d"
                    VolumeType: "gp3"
                    DeleteOnTermination: true
            Tags: 
              - 
                Key: "Name"
                Value: "aaron-test"
            HibernationOptions: 
                Configured: false
            EnclaveOptions: 
                Enabled: false

