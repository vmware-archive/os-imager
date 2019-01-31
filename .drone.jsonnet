local Lint(os, os_version) = {

  kind: 'pipeline',
  name: 'lint-' + os + '-' + os_version,
  steps: [
    {
      name: 'lint-' + os + '-' + os_version,
      image: 'hashicorp/packer',
      commands: [
        'apk --no-cache add make',
        'make validate OS=' + os + ' OS_REV=' + os_version,
      ],
     when: { event: ['pull_request'] }
    }
  ]
};
local Build(os, os_version) = {
  kind: 'pipeline',
  name: 'build-' + os + '-' + os_version,
  steps: [
    {
      name: 'build-' + os + '-' + os_version,
      image: 'hashicorp/packer',
      environment: {
        "AWS_DEFAULT_REGION": "us-west-2",
        "AWS_ACCESS_KEY_ID": {
        "from_secret": "username"
    },
         "AWS_SECRET_ACCESS_KEY": {
         "from_secret": "password"
    }
  },
      commands: [
        'apk --no-cache add make',
        'make build OS=' + os + ' OS_REV=' + os_version,
      ],
      when: { ref: ['refs/tags/v1.*'] }
    }
  ]
};
local Secret() = {
  kind: 'secret',
    "data": {
      "username": "I0tTPep0OuH_qwx5v5-cr4gONWEDbccbJ4yShpI369wV5WYYRuq1Gckx40A6_OK_ypQ4AfAiDjEsC2U=",
      "password": "ood6DhiPeWBKZfSOqhsq-iJPmkfnrbdIonynU7Hdd_gTk4eeii_l4cbit9O3s5P-iX3CWa_v6RwKtKz9vQd6V0MuphwGxRAcSC1z4O3R0g=="
    }
};

local distros = [
  { name: 'arch', version: '2019-01-09' },
  { name: 'centos', version: '6' },
  { name: 'centos', version: '7' },
  { name: 'debian', version: '8' },
  { name: 'debian', version: '9' },
  { name: 'fedora', version: '28' },
  { name: 'fedora', version: '29' },
  { name: 'opensuse', version: '15.0' },
  { name: 'opensuse', version: '42.3' },
  { name: 'ubuntu', version: '14.04' },
  { name: 'ubuntu', version: '16.04' },
  { name: 'ubuntu', version: '18.04' },
  { name: 'windows', version: '2016' },
];


[
  Lint(distro.name, distro.version)
  for distro in distros
] + [
  Build(distro.name, distro.version)
  for distro in distros
]  + [
  Secret()
]
