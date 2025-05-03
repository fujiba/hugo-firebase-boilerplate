# hugo-firebase-boilerplate

Hugo ベースの Web サイトを Firebase 上に構築・デプロイするためのボイラープレートプロジェクトです。

本リポジトリをテンプレートにしてプロジェクトを作成し、いくつかの設定後に環境を作ることで、以下のワークフローを実現できます。

- `development` ブランチへマージ → BASIC 認証付きの確認用サイトへデプロイ
- `main` ブランチへマージ → 本番サイトへデプロイ

Hugo については初期状態 (`hugo new site`) で置いていますので、ここからお好みのテーマやテンプレートを導入して構築することで、手早くサイトを立ち上げられます。

なお、確認用サイトの BASIC 認証のために Firebase Cloud Functions を使用する場合 (後述の `setup.deployOnCommitDevelop` を `true` に設定した場合)、Firebase の **Blaze プラン** が必要になります。

## 前提条件

以下のコマンドが利用可能であることを確認してください。

- firebase(firebase-tools)
- gcloud(gcloud CLI)
- gh(Github CLI)
- yq(jq wrapper for YAML)
- direnv (環境変数の管理に使用します)

## 環境構築手順

以下の手順で環境を構築します。

1. **初期設定の実行 (`npm run init`)**
2. **Terraform でのインフラ構築 (`terraform apply`)**
3. **(オプション) Terraform リモートバックエンドの設定**
4. **Hugo のセットアップ**
5. **Firebase 関連の設定 (`scripts/setup-firebase.sh`)**

### 1. 初期設定の実行 (`npm run init`)

まず、プロジェクトのルートディレクトリで以下のコマンドを実行します。

```bash
npm run init
```

このコマンドは `scripts/init-setup.sh` を実行し、以下の処理を行います。

- **`config.yaml` の生成:**
  - `config.yaml` が存在しない場合、対話形式で以下の設定値を質問し、`config.yaml` を生成します。
    - **Hugo Version:** 使用する Hugo のバージョン (デフォルト: `latest`)。
    - **Deploy on Commit Develop:** `develop` ブランチへのコミット時に確認用サイトへ自動デプロイするかどうか (`true`/`false`, デフォルト: `false`)。
    - **Firebase Project ID Prefix:** 作成する Firebase プロジェクト ID のプレフィックス (6〜29文字、小文字英数字ハイフン、英字始まり)。Terraform がこの後ろにランダムな文字列を付加して一意な ID を生成します。
    - **Firebase Project Display Name:** Firebase プロジェクトの表示名 (4〜30文字)。
  - `config.yaml` が既に存在する場合は、この対話部分はスキップされます。
- **Billing Account ID の入力 (条件付き):**
  - `config.yaml` の `setup.deployOnCommitDevelop` が `true` の場合 (確認用サイト機能を使う場合)、Blaze プランが必要になるため、Billing Account ID の入力を求められます (任意入力)。
- **Terraform 用環境変数ファイル (`.envrc`) の生成:**
  - `config.yaml` の値と入力された Billing Account ID をもとに、`terraform/.envrc` ファイルを生成します。このファイルは `direnv` によって読み込まれ、Terraform 実行時に必要な変数を設定します。

**注意:**

- プロジェクト ID はグローバルで一意である必要があるため、プレフィックスは他と重複しにくいものを指定してください。
- 生成された `config.yaml` や `terraform/.envrc` の内容を確認し、必要に応じて編集してください。特に Billing Account ID は後からでも設定可能です。

| `config.yaml` の項目        | 説明                                                                                                 |
| --------------------------- | ---------------------------------------------------------------------------------------------------- |
| `setup.hugoVersion`           | 利用する Hugo のバージョン。                                                                         |
| `setup.deployOnCommitDevelop` | `develop` ブランチへのコミット時に確認用サイトへ自動デプロイするかどうか。                             |
| `firebase.projectIdPrefix`    | 作成する Firebase プロジェクト ID のプレフィックス。                                                   |
| `firebase.projectName`        | Firebase プロジェクトの表示名。                                                                      |

### 2. Terraform でのインフラ構築 (`terraform apply`)

Terraform を使用して、Firebase プロジェクトや Hosting サイトなどのインフラを構築します。デフォルトでは、Terraform の状態ファイル (`.tfstate`) はローカル (`terraform` ディレクトリ内) に作成されます。

複数人での開発や CI/CD との連携を行う場合は、手順 3 に従ってリモートバックエンド (GCS) の設定を行うことを強く推奨します。

`terraform` ディレクトリに移動し、`direnv allow` で環境変数を適用後、`terraform init` と `terraform apply` を実行します。

```sh
cd terraform
direnv allow # .envrc の内容を環境変数として読み込み
terraform init
terraform apply
```

`apply` が完了すると、実際に作成されたプロジェクト ID が Output として表示されます。

### 3. (オプション) Terraform リモートバックエンドの設定

複数人で開発する場合や CI/CD と連携する場合は、Terraform の状態ファイル (`.tfstate`) をローカルではなく、GCS バケットなどのリモートバックエンドに保存することが推奨されます。

1. **GCS バケットの作成:**
    状態ファイル保存用の GCS バケットを作成します。以下のスクリプトを実行すると、対話的にバケットを作成できます。

    ```bash
    scripts/create-tf-backend-bucket.sh
    ```

    スクリプトは、バケット作成先のプロジェクト ID を `-p` オプションで指定するか、`gcloud` に設定されているプロジェクトを使用します。事前に `gcloud config set project <プロジェクトID>` を実行しておくとスムーズです。

2. **`backend.tf` の設定:**
    スクリプトの最後に `terraform/backend.tf` を自動更新するか尋ねられます。`y` と答えると、作成したバケット名で `backend.tf` が更新されます。手動で更新する場合は、`terraform/backend.tf` のコメントアウトを解除し、`bucket` に作成したバケット名を設定してください。

3. **Terraform の再初期化:**
    `terraform` ディレクトリで以下のコマンドを実行し、バックエンド設定を反映させます。

    ```bash
    cd terraform
    terraform init -reconfigure
    ```

    ローカルの状態をリモートに移行するか尋ねられるので、`yes` と答えます。

### 4. Hugo のセットアップ

初期時点では、website 配下に空の hugo プロジェクトが置かれている状態です。(hugo init 直後の状態)
テーマなどを適宜インストールし、コンテンツを作成してください。

すでに hugo でサイトを作っている場合は、このディレクトリにコピーしてください。

### 5. Firebase 関連の設定 (`scripts/setup-firebase.sh`)

`terraform apply` が完了した後、プロジェクトのルートディレクトリで以下のスクリプトを実行します。

```sh
scripts/setup-firebase.sh
```

```text
Now using project {project-id}
✔  Applied hosting target prod to {project-id}
Updated: prod ({project-id})
✔  Applied hosting target dev to dev-{project-id} # dev環境のサイトIDは dev- がプレフィックス
Updated: dev (dev-{project-id})
? Enter a value for BASIC_AUTH_USER [input is hidden] ここに入力
✔  Created a new secret version projects/************/secrets/BASIC_AUTH_USER/versions/1
? Enter a value for BASIC_AUTH_PASSWORD [input is hidden] ここに入力
✔  Created a new secret version projects/************/secrets/BASIC_AUTH_PASSWORD/versions/1
```

このスクリプトは、Terraform が生成したプロジェクト ID を自動で読み取り、Firebase CLI の設定（使用するプロジェクトの切り替え、Hosting のデプロイターゲット設定）を行います。

また、`config.yaml` の `setup.deployOnCommitDevelop` が `true` の場合は、確認用サイトのデプロイターゲット設定と、BASIC 認証用のユーザー名・パスワードを Secret Manager に登録するためのプロンプトが表示されます。

## デプロイ (Deployment)

### 手動デプロイ (Manual Deploy)

手動でデプロイする場合は、以下の npm スクリプトを実行します。

- 本番環境
  `npm run dev:prod`
- 開発環境
  `npm run dev:dev`

### 自動デプロイ (GitHub Actions) (Automatic Deploy)

GitHub Actions では、`website` ディレクトリ配下のファイルがコミットされると、対応するブランチに応じて自動でデプロイが実行されます。

自動デプロイを行うために、Terraform が生成した GCP サービスアカウントのキーファイルを GitHub リポジトリの Secrets に設定する必要があります。

Terraform 実行後、`terraform/output/secrets/deployuser-key` にキーファイルが生成されます。このファイルの内容全体をコピーし、GitHub リポジトリの `Settings` > `Secrets and variables` > `Actions` に `GCLOUD_SERVICE_KEY` という名前で登録してください。
あるいは、下記のコマンドを実行して登録することもできます。

```sh
gh secret set GCLOUD_SERVICE_KEY < terraform/output/secrets/deployuser-key
```
