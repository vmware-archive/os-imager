local distros = [
  // Multiprier is way to throttle API requests in order not to hit the limits
  { display_name: 'Arch', name: 'arch', version: '2019-01-09', multiplier: 1 },
  { display_name: 'CentOS 6', name: 'centos', version: '6', multiplier: 2 },
  { display_name: 'CentOS 7', name: 'centos', version: '7', multiplier: 3 },
  { display_name: 'Debian 8', name: 'debian', version: '8', multiplier: 4 },
  { display_name: 'Debian 9', name: 'debian', version: '9', multiplier: 5 },
  { display_name: 'Fedora 28', name: 'fedora', version: '28', multiplier: 6 },
  { display_name: 'Fedora 29', name: 'fedora', version: '29', multiplier: 7 },
  { display_name: 'Opensuse 15', name: 'opensuse', version: '15', multiplier: 8 },
  { display_name: 'Opensuse 42.3', name: 'opensuse', version: '42.3', multiplier: 9 },
  { display_name: 'Ubuntu 1404', name: 'ubuntu', version: '1404', multiplier: 10 },
  { display_name: 'Ubuntu 1604', name: 'ubuntu', version: '1604', multiplier: 11 },
  { display_name: 'Ubuntu 1804', name: 'ubuntu', version: '1804', multiplier: 12 },
  // Windows builds have a 0 multiplier because we want them to start first and they are few enough not to hit API limits
  //  { display_name: 'Windows 2008r2', name: 'windows', version: '2008r2', multiplier: 0 },
  { display_name: 'Windows 2012r2', name: 'windows', version: '2012r2', multiplier: 0 },
  { display_name: 'Windows 2016', name: 'windows', version: '2016', multiplier: 0 },
  { display_name: 'Windows 2019', name: 'windows', version: '2019', multiplier: 0 },
];

local BuildTrigger() = {
  ref: [
    'refs/tags/v2.*',
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
  '2017.7',
  '2018.3',
  '2019.2',
  'develop',
];


local Lint() = {
  kind: 'pipeline',
  name: 'Lint',
  steps: [
    {
      name: distro.display_name,
      image: 'hashicorp/packer',
      commands: [
        'apk --no-cache add make',
        std.format('make validate OS=%s OS_REV=%s', [distro.name, distro.version]),
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
          { offset: 7 * std.length(salt_branches) * distro.multiplier }
        ),
      ],
    },
  ] + [
    {
      name: salt_branch,
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
        'apk --no-cache add make curl grep gawk sed',
        std.format('make build%s OS=%s OS_REV=%s SALT_BRANCH=%s', [
          if staging then '-staging' else '',
          distro.name,
          distro.version,
          salt_branch,
        ]),
      ],
      depends_on: [
        'throttle-build',
      ],
    }
    for salt_branch in salt_branches
  ],
  trigger: if staging then StagingBuildTrigger() else BuildTrigger(),
  depends_on: [
    'Lint',
  ],
};

local Secret() = {
  kind: 'secret',
  data: {
    username: 'I0tTPep0OuH_qwx5v5-cr4gONWEDbccbJ4yShpI369wV5WYYRuq1Gckx40A6_OK_ypQ4AfAiDjEsC2U=',
    password: 'ood6DhiPeWBKZfSOqhsq-iJPmkfnrbdIonynU7Hdd_gTk4eeii_l4cbit9O3s5P-iX3CWa_v6RwKtKz9vQd6V0MuphwGxRAcSC1z4O3R0g==',
  },
};

[
  Lint(),
] + [
  Build(distro, false)
  for distro in distros
] + [
  Build(distro, true)
  for distro in distros
] + [
  Secret(),
]
