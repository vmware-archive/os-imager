local distros = [
  { display_name: 'CentOS 7', name: 'centos', version: '7', multiplier: 0 },
];

local BuildTrigger() = {
  ref: [
    'refs/tags/aws-jenkins-slave-v1.*',
  ],
  event: [
    'tag',
  ],
};

local StagingBuildTrigger() = {
  event: [
    'push',
  ],
  branch: [
    'jenkins-slaves',
  ],
};

local Lint() = {

  kind: 'pipeline',
  name: 'Lint',
  steps: [
    {
      name: distro.display_name,
      image: 'hashicorp/packer',
      commands: [
        'apk --no-cache add --update py3-pip',
        'pip3 install --upgrade pip setuptools',
        'pip3 install invoke',
        std.format('inv build-aws --validate --distro=%s --distro-version=%s', [
          distro.name,
          distro.version,
        ]),
      ],
      depends_on: [
        'clone',
      ],
    }
    for distro in distros
  ],
};

local Build(distro, staging) = {
  kind: 'pipeline',
  name: std.format('%s%s', [distro.display_name, if staging then ' (Staging)' else '']),
  steps: [
    {
      name: 'slave-image',
      image: 'hashicorp/packer',
      environment: {
        AWS_DEFAULT_REGION: 'us-west-2',
        AWS_ACCESS_KEY_ID: {
          from_secret: 'username',
        },
        AWS_SECRET_ACCESS_KEY: {
          from_secret: 'password',
        },
        GPGKEY: {
          from_secret: 'gpgkey',
        },
        SSHKEY: {
          from_secret: 'sshkey',
        },
      },
      commands: [
        'apk --no-cache add make curl grep gawk sed openssh-client py3-pip',
        'pip3 install --upgrade pip setuptools',
        'pip3 install invoke',
        'echo "$SSHKEY" > sre-jenkins-key',
        'echo "$GPGKEY" > gpgkey.asc',
        'chmod 600 sre-jenkins-key gpgkey.asc',
        'ssh-keyscan -t rsa github.com | ssh-keygen -lf -',
        'mkdir ~/.ssh',
        'chmod 700 ~/.ssh',
        'ssh-keyscan -H github.com >> ~/.ssh/known_hosts',
        std.format('inv build-aws%s --distro=%s --distro-version=%s', [
          if staging then ' --staging' else '',
          distro.name,
          distro.version,
        ]),
      ],
      depends_on: [
        'clone',
      ],
    },
  ] + [
    {
      name: 'delete-old-amis',
      image: 'alpine',
      environment: {
        AWS_DEFAULT_REGION: 'us-west-2',
        AWS_ACCESS_KEY_ID: {
          from_secret: 'username',
        },
        AWS_SECRET_ACCESS_KEY: {
          from_secret: 'password',
        },
      },
      commands: [
        'apk --no-cache add --update py3-pip jq',
        'pip3 install --upgrade pip setuptools',
        'pip3 install awscli',
        |||
          ami_filter=$(cat manifest.json | jq -r '.builds[].custom_data.ami_name')
          echo "AMI FILTER: $ami_filter"
          aws ec2 --region $AWS_DEFAULT_REGION describe-images --filters "Name=name,Values=$ami_filter/*" --query "sort_by(Images, &CreationDate)[].ImageId" | jq 'del(.[-1])' | jq -r ".[]" > amis.txt
          cat amis.txt
        |||,
        std.format(
          |||
            for ami in $(head -n -%s amis.txt); do
              echo "Deleting AMI $ami"
              aws ec2 --region $AWS_DEFAULT_REGION deregister-image --image-id $ami || echo "Failed to delete AMI $ami"
            done
          |||,
          // Keep 1 staging build and 3 regular builds at all times
          // The values below are 0 and 2 because the AMI built on this run is never part of the listing
          [if staging then 0 else 2]
        ),
      ],
      depends_on: [
        'slave-image',
      ],
    },
  ],
  trigger: if staging then StagingBuildTrigger() else BuildTrigger(),
  depends_on: [
    'Lint',
  ],
};


[
  Lint(),
] + [
  Build(distro, false)
  for distro in distros
] + [
  Build(distro, true)
  for distro in distros
]
