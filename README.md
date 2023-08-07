# aws-terraform

### Requirements

- terraform ~> 1.5.x

### Description

- gcp環境のインフラ構成をテストするterraformです
- (予定)公開したくない情報はgcpの環境変数に定義します
- (予定)CI/CDを組みたい

### Directory Layout

```text
C:.
│  .gitignore
│  backend.tf
│  ${etc}.tf
│  README.md
│
└─module
    └─${asset}
        │  variables.tf.tf
        └─ main.tf
```