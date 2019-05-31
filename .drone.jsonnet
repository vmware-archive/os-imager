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
        'apk --no-cache add --update python3',
        'python3 -m ensurepip',
        'rm -r /usr/lib/python*/ensurepip',
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
      name: 'throttle-build',
      image: 'alpine',
      commands: [
        std.format(
          "sh -c 'echo Sleeping %(offset)s seconds; sleep %(offset)s'",
          { offset: 7 * distro.multiplier }
        ),
      ],
    },
  ] + [
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
        'apk --no-cache add make curl grep gawk sed openssh-client',
        'apk --no-cache add --update python3',
        'python3 -m ensurepip',
        'rm -r /usr/lib/python*/ensurepip',
        'pip3 install --upgrade pip setuptools',
        'pip3 install invoke',
        'printf "$SSHKEY" > sre-jenkins-key',
        'echo ---',
        'head -c 150 sre-jenkins-key',
        'echo ---',
        'printf "$GPGKEY" > gpgkey.asc',
        'echo ---',
        'head -c 150 gpgkey.asc',
        'echo ---',
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
        'throttle-build',
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
