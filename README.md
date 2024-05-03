
## 環境を作る

以下の流れで環境を構築環境をします。

* terraformでfirebaseのプロジェクト、サイトを作成する
* hugoのセットアップ
* firebase functionsのBASIC認証設定
* デプロイ

### terraformの実行

`terraform/environments/usedev`へ移動し、.envrcを作成します。

```.envrc
export TF_VAR_project_id=`firebaseのプロジェクトID`
export TF_VAR_project_name=`firebaseプロジェクトの表示名`
export TF_VAR_billing_account=`firebaseの支払いアカウントID`
```

firebaseの支払いアカウントIDは、[ここ](https://cloud.google.com/billing/docs/how-to/find-billing-account-id?hl=ja)を参照してください。

direnv allowにて環境変数を適用後、terraform init, terraform applyで環境を構築します。

```sh
direnv allow
terraform init
terraform apply
```

NOTE:
現在、下記警告でますがひとまず置いてますorz

```sh
│ Warning: Reference to undefined provider
│ 
│   on main.tf line 18, in module "project":
│   18:     google-beta.no_user_project_override = google-beta.no_user_project_override
│ 
│ There is no explicit declaration for local provider name "google-beta.no_user_project_override" in module.project, so Terraform is assuming you mean to pass a configuration for
│ "hashicorp/google-beta".
│ 
│ If you also control the child module, add a required_providers entry named "google-beta.no_user_project_override" with the source address "hashicorp/google-beta".
```

### hugoのセットアップ

初期時点では、website配下に空のhugoプロジェクトが置かれている状態です。(hugo init直後の状態)
テーマなどを適宜インストールし、コンテンツを作成してください。

すでにhugoでサイトを作っている場合は、このディレクトリにコピーしてください。

### firebase関連の設定、BASIC認証の認証情報設定

`scripts/setup-firebase.sh {project-id}`を実行し、firebaseのプロジェクト切り替え、デプロイターゲットおよび、BAISC認証設定をします。

```sh
scripts/setup-firebase.sh {project-id}
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

firebase functionsの環境変数として、BAISC認証のユーザー名とパスワードを設定する。
Secret Managerに、`BASIC_AUTH_USER`と`BASIC_AUTH_PASSWORD`として登録しているので、以下、firebase CLIで入力する。

## デプロイ

デプロイは、npm run dev:{target}で実行します。

* 本番環境
`npm run dev:prod`
* 開発環境
`npm run dev:dev`
