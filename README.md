# hugo-firebase-bolierplate

Hugo ベースな Web サイトを、firebase 上に構築・デプロイするためのボイラープレートプロジェクトです。

本リポジトリをテンプレートにして、プロジェクトを作成し、いくつかの設定後に環境を作ることで、

- development ブランチへマージしたら、BASIC 認証なサイトへデプロイ(リリース前の確認ができる)
- main ブランチへマージしたら、本番サイトへデプロイ

というワークフローを回すことができます。

Hugo については空っぽの状態で置いているので、そこから適宜自分好みのテンプレートを持ってきて構築することで、手早くサイトの立ち上げができます。

なお、BASIC 認証のために Firebase Cloud functions を使っているため、Blaze プランになります。

## 前提条件

下記コマンドが利用可能となるようにしてください。

- firebase(firebase-tools)
- gcloud(gcloud CLI)
- gh(Github CLI)
- yq(jq wrapper for YAML)
- direnv

## 環境を作る

以下の流れで環境を構築環境をします。

- 設定ファイル更新(config.yaml)
- terraform で firebase のプロジェクト、サイトを作成する
- hugo のセットアップ
- firebase functions の BASIC 認証設定
- デプロイ

### 設定ファイル更新

config.yaml を編集して、必要な設定をします。

| 項目                        | 説明                                                                                                 |
| --------------------------- | ---------------------------------------------------------------------------------------------------- |
| setup.hugoVersion           | 利用する Hugo のバージョン、最新を使う場合は`latest`とする                                           |
| setup.deployOnCommitDevelop | develop ブランチにコミット(マージ)した時に確認用サイトのデプロイをするかどうか。`true`でデプロイする |
| firebase.projectId          | firebase のプロジェクト ID を指定する。この ID を使って新規に firebase プロジェクトを作成します。    |
| firebase.projectName        | firebsae のプロジェクト表示名                                                                        |

### terraform の実行

terraformにて、本番環境のみ、開発環境込みの２通りの環境を作成することができます。

- `terraform/environments/prodonly` : 本番環境のみの構成(Sparkプランでの利用可能)
- `terraform/environments/usedev` : 開発環境(ステージング用途)込みの構成(Sparkプランでの利用可能)

terraform実行前に、`scripts/prepare-terraform.sh`を実行し、各環境の.envrcファイルを作成します。
firebaseのプロジェクトIDおよび表示名をconfig.yamlから取得して生成します。

developからのデプロイをする場合は、firebaseのBlazeプランを使う必要があるため、`TF_VAR_billing_account`にfirbaseの支払いアカウントIDを設定してください。

firebase の支払いアカウント ID は、[ここ](https://cloud.google.com/billing/docs/how-to/find-billing-account-id?hl=ja)を参照してください。

```.envrc
export TF_VAR_project_id=`firebaseのプロジェクトID`           # config.yamlから自動設定
export TF_VAR_project_name=`firebaseプロジェクトの表示名`     # config.yamlから自動設定
export TF_VAR_billing_account=`firebaseの支払いアカウントID`
```

利用する環境のディレクトリ移動し、direnv allow にて環境変数を適用後、terraform init, terraform apply で環境を構築します。

```sh
direnv allow
terraform init
terraform apply
```

## プロジェクトの削除について

Terraform の設定では、安全のためプロジェクト自体の削除を禁止しています 。

もし Terraform で作成したプロジェクトを削除したい場合は、Google Cloud Console にログインし、対象のプロジェクトを選択して手動でシャットダウン（削除）してください。

### hugo のセットアップ

初期時点では、website 配下に空の hugo プロジェクトが置かれている状態です。(hugo init 直後の状態)
テーマなどを適宜インストールし、コンテンツを作成してください。

すでに hugo でサイトを作っている場合は、このディレクトリにコピーしてください。

### firebase 関連の設定、BASIC 認証の認証情報設定

`scripts/setup-firebase.sh`を実行し、firebase のプロジェクト切り替え、デプロイターゲットおよび、BAISC 認証設定をします。
BASIC認証設定や、dev環境設定はconfig.yamlにて`setup.deployOnCommitDevelop`が`true`になっている場合のみ行います。

```sh
scripts/setup-firebase.sh
Now using project {project-id}
✔  Applied hosting target prod to {project-id}
Updated: prod ({project-id})
✔  Applied hosting target dev to {project-id}
Updated: dev (dev-{project-id})
? Enter a value for BASIC_AUTH_USER [input is hidden] ここに入力
✔  Created a new secret version projects/************/secrets/BASIC_AUTH_USER/versions/1
? Enter a value for BASIC_AUTH_PASSWORD [input is hidden] ここに入力
✔  Created a new secret version projects/************/secrets/BASIC_AUTH_PASSWORD/versions/1
```

firebase functions の環境変数として、BAISC 認証のユーザー名とパスワードを設定する。
Secret Manager に、`BASIC_AUTH_USER`と`BASIC_AUTH_PASSWORD`として登録しているので、以下、firebase CLI で入力する。

## デプロイ

手動でのデプロイは、npm run dev:{target}で実行します。

- 本番環境
  `npm run dev:prod`
- 開発環境
  `npm run dev:dev`

Github actionsでは、website配下のコミットがあれば自動でデプロイされます。

### Github actions でデプロイするための準備

firebaseのデプロイを行うための、GCPサービスアカウントのキー関連情報をSecretsに保存します。
以下のコマンドを実行することでSecretsへ保存することができます。

```sh
gh secret set GOOGLE_APPLICATION_CREDENTIALS --body '/tmp/cred.json'
gh secret set GCLOUD_SERVICE_KEY < terraform/environments/{構築対象環境}/output/secrets/deployuser-key
```

## Lisence

This project is licensed under the MIT License, see the LICENSE.txt file for details
