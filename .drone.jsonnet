local distros = [
  // Multiprier is way to throttle API requests in order not to hit the limits
  { display_name: 'Arch', name: 'arch', version: '2019-01-09', multiplier: 1 },
  { display_name: 'Amazon 1', name: 'amazon', version: '1', multiplier: 2 },
  { display_name: 'Amazon 2', name: 'amazon', version: '2', multiplier: 3 },
  { display_name: 'CentOS 6', name: 'centos', version: '6', multiplier: 4 },
  { display_name: 'CentOS 7', name: 'centos', version: '7', multiplier: 5 },
  { display_name: 'Debian 8', name: 'debian', version: '8', multiplier: 6 },
  { display_name: 'Debian 9', name: 'debian', version: '9', multiplier: 6 },
  { display_name: 'Fedora 29', name: 'fedora', version: '29', multiplier: 5 },
  { display_name: 'Fedora 30', name: 'fedora', version: '30', multiplier: 4 },
  { display_name: 'Opensuse 15', name: 'opensuse', version: '15', multiplier: 3 },
  { display_name: 'Ubuntu 1604', name: 'ubuntu', version: '1604', multiplier: 2 },
  { display_name: 'Ubuntu 1804', name: 'ubuntu', version: '1804', multiplier: 1 },
  // Windows builds have a 0 multiplier because we want them to start first and they are few enough not to hit API limits
  //  { display_name: 'Windows 2008r2', name: 'windows', version: '2008r2', multiplier: 0 },
  { display_name: 'Windows 2012r2', name: 'windows', version: '2012r2', multiplier: 0 },
  { display_name: 'Windows 2016', name: 'windows', version: '2016', multiplier: 0 },
  { display_name: 'Windows 2019', name: 'windows', version: '2019', multiplier: 0 },
];

local BuildTrigger() = {
  ref: [
    'refs/tags/aws-ci-v1.*',
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
    'ci',
  ],
};

local salt_branches = [
  /*
   * These are the salt branches, which map to salt-jenkins branches
   */
  { multiplier: 1, name: '2017.7' },
  { multiplier: 3, name: '2018.3' },
  { multiplier: 5, name: '2019.2' },
  { multiplier: 7, name: 'neon' },
  { multiplier: 9, name: 'develop' },
];


local Lint() = {
  kind: 'pipeline',
  name: 'Lint',
  steps: [
    {
      name: distro.display_name,
      image: 'hashicorp/packer',
      commands: [
        'apk --no-cache add --update py3-pip',
        'pip3 install --upgrade pip',
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
      name: salt_branch.name,
      image: 'hashicorp/packer',
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
        std.format(
          "sh -c 'echo Sleeping %(offset)s seconds; sleep %(offset)s'",
          { offset: (2 * salt_branch.multiplier * std.length(salt_branches) * distro.multiplier) + (salt_branch.multiplier * 13) }
        ),
        'apk --no-cache add make curl grep gawk sed py3-pip',
        'pip3 install --upgrade pip',
        'pip3 install invoke',
        std.format('inv build-aws%s --distro=%s --distro-version=%s --salt-branch=%s', [
          if staging then ' --staging' else '',
          distro.name,
          distro.version,
          salt_branch.name,
        ]),
      ],
      depends_on: [
        'clone',
      ],
    }
    for salt_branch in salt_branches
  ] + [
    {
      name: std.format('delete-old-%s-amis', [salt_branch.name]),
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
        'pip3 install --upgrade pip',
        'pip3 install -r requirements/py3.5/base.txt',
        'cat %(salt_branch)s-manifest.json | jq',
        'export name_filter=$(cat %(salt_branch)s-manifest.json | jq -r ".builds[].custom_data.ami_name")',
        'echo "Name Filter: $name_filter"',
        'inv cleanup-aws --region=$AWS_DEFAULT_REGION --name-filter=$name_filter --assume-yes --num-to-keep=1',
      ],
      depends_on: [
        salt_branch.name,
      ],
    }
    for salt_branch in salt_branches
  ]
  ,
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
