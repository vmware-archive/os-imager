local linux_distros = [
  { name: 'arch', version: '2019-01-09' },
  { name: 'centos', version: '6' },
  { name: 'centos', version: '7' },
  { name: 'debian', version: '8' },
  { name: 'debian', version: '9' },
  { name: 'fedora', version: '28' },
  { name: 'fedora', version: '29' },
  { name: 'opensuse', version: '15' },
  { name: 'opensuse', version: '42.3' },
  { name: 'ubuntu', version: '1404' },
  { name: 'ubuntu', version: '1604' },
  { name: 'ubuntu', version: '1804' },
];

local win_distros = [
#  { name: 'windows', version: '2008r2' },
  { name: 'windows', version: '2012r2' },
  { name: 'windows', version: '2016' },
  { name: 'windows', version: '2019' },
];

local Lint(os, os_version) = {

  kind: 'pipeline',
  name: std.format('lint-%s-%s', [os, os_version]),
  steps: [
    {
      name: std.format('lint-%s-%s', [os, os_version]),
      image: 'hashicorp/packer',
      commands: [
        'apk --no-cache add make',
        std.format('make validate OS=%s OS_REV=%s', [os, os_version]),
      ],
      when: {
        event: [
          'pull_request',
        ],
      },
    },
  ],
};


local Step(os, os_version) = {
  name: 'base-image',
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
    'apk --no-cache add make',
    std.format('make build OS=%s OS_REV=%s', [os, os_version]),
  ],
  when: {
    ref: [
      'refs/tags/v1.*',
    ],
  },
};


local Build(os, os_version) = {
  kind: 'pipeline',
  name: std.format('build-%s-%s', [os, os_version]),
  steps: [
    {
      name: 'throttle build',
      image: 'alpine',
      commands: [
        "sh -c 't=$(shuf -i 30-180 -n 1); echo Sleeping $t seconds; sleep $t'",
      ],
      when: {
        ref: [
          'refs/tags/v1.*',
        ],
      },
    },
    Step(os, os_version),
  ],
};


local WindowBuild(os, os_version) = {
  kind: 'pipeline',
  name: std.format('build-%s-%s', [os, os_version]),
  steps: [Step(os, os_version)],
};

local Secret() = {
  kind: 'secret',
  data: {
    username: 'I0tTPep0OuH_qwx5v5-cr4gONWEDbccbJ4yShpI369wV5WYYRuq1Gckx40A6_OK_ypQ4AfAiDjEsC2U=',
    password: 'ood6DhiPeWBKZfSOqhsq-iJPmkfnrbdIonynU7Hdd_gTk4eeii_l4cbit9O3s5P-iX3CWa_v6RwKtKz9vQd6V0MuphwGxRAcSC1z4O3R0g==',
  },
};


[
  Lint(distro.name, distro.version)
  for distro in linux_distros + win_distros
] + [
  Build(distro.name, distro.version)
  for distro in linux_distros
] + [
  WindowBuild(distro.name, distro.version)
  for distro in win_distros
] + [
  Secret(),
]
