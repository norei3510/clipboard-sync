# Clipboard Sync API

Windows と iPhone の間で、テキスト・画像・任意ファイルをローカル LAN 経由で共有する FastAPI アプリです。

## 構成

```text
clipboard-sync/
  main.py
  requirements.txt
  .env
  .env.example
  start-server.ps1
  start-server.bat
  start-server-hidden.vbs
  stop-server.bat
  install-startup-task.bat
  uninstall-startup-task.bat
  status-startup-task.bat
  allow-firewall.ps1
  allow-firewall.bat
  test-api.ps1
  test-api.bat
  README.md
  uploads/
    images/
    files/
```

## セットアップ

PowerShell でこのディレクトリに移動します。

```powershell
cd path\to\clipboard-sync
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Python を入れ直して `.venv` を作る場合:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

`.env` には次の API トークンを設定済みです。

```env
API_TOKEN=YOUR_API_TOKEN
```

## 起動

```bat
start-server.bat
```

または:

```powershell
.\start-server.ps1
```

起動すると `http://0.0.0.0:8787` で待ち受けます。

バックグラウンドで起動したサーバーを止める場合:

```bat
stop-server.bat
```

## PC起動中いつでも使えるようにする

Windows にログオンしたとき、自動で `start-server.bat` が非表示起動するランチャーを登録できます。登録は管理者権限なしで、スタートアップフォルダと現在ユーザーの `Run` レジストリに入ります。

```bat
install-startup-task.bat
```

登録状態を確認:

```bat
status-startup-task.bat
```

自動起動をやめる:

```bat
uninstall-startup-task.bat
```

登録後は、次回ログオンから Clipboard Sync API が自動起動します。すぐ使いたい場合は、その場で `start-server.bat` も実行してください。

自動起動時のログは `logs/server.log` に出ます。スマホから接続できないときは、まず `status-startup-task.bat` と `logs/server.log` を確認してください。

iPhone からは Windows PC の LAN 内 IP アドレスを使います。現在この PC の Wi-Fi IPv4 アドレスは `YOUR_PC_IP` です。

```text
http://YOUR_PC_IP:8787
```

IP アドレスが変わった場合は Windows 側で `ipconfig` を実行し、Wi-Fi の `IPv4 Address` を確認してください。

## 認証

すべての API で `X-API-Key` ヘッダーが必要です。

```text
X-API-Key: YOUR_API_TOKEN
```

## API

### テキスト

Windows のテキストクリップボードを取得:

```powershell
curl -H "X-API-Key: YOUR_API_TOKEN" http://127.0.0.1:8787/clipboard/text
```

Windows のテキストクリップボードへコピー:

```powershell
curl -X POST ^
  -H "X-API-Key: YOUR_API_TOKEN" ^
  -H "Content-Type: text/plain" ^
  -d "hello from iPhone" ^
  http://127.0.0.1:8787/clipboard/text
```

`POST /clipboard/text` は `text/plain` の本文そのものと、`application/json` の `{"text": "..."}` の両方に対応しています。

### 画像

画像をアップロードして `uploads/images` に保存します。可能なら Windows のクリップボードにも画像として入れます。

```powershell
curl -X POST ^
  -H "X-API-Key: YOUR_API_TOKEN" ^
  -F "file=@C:\path\to\image.png" ^
  http://127.0.0.1:8787/clipboard/image
```

最新の画像を取得:

```powershell
curl -H "X-API-Key: YOUR_API_TOKEN" ^
  -o latest-image.png ^
  http://127.0.0.1:8787/clipboard/image/latest
```

### ファイル

任意のファイルをアップロードして `uploads/files` に保存します。可能なら Windows のクリップボードにもファイルとして登録します。

```powershell
curl -X POST ^
  -H "X-API-Key: YOUR_API_TOKEN" ^
  -F "file=@C:\path\to\document.pdf" ^
  http://127.0.0.1:8787/clipboard/file
```

最新のファイルを取得:

```powershell
curl -H "X-API-Key: YOUR_API_TOKEN" ^
  -o latest-file ^
  http://127.0.0.1:8787/clipboard/file/latest
```

## iPhone ショートカットから使う

iPhone と Windows PC を同じ Wi-Fi / LAN に接続してください。以下では Windows PC の IP を `YOUR_PC_IP` とします。

### iPhone のテキストを Windows に送る

1. 「ショートカット」アプリで新規ショートカットを作成します。
2. アクション「クリップボードを取得」を追加します。
3. アクション「URL」を追加し、`http://YOUR_PC_IP:8787/clipboard/text` を入力します。
4. アクション「URL の内容を取得」を追加します。
5. 「方法」を `POST` にします。
6. 「ヘッダ」に `X-API-Key: YOUR_API_TOKEN` と `Content-Type: text/plain` を追加します。
7. 「要求本文」を `テキスト` にし、手順2の「クリップボード」を指定します。

### Windows のテキストを iPhone に取り込む

1. アクション「URL」を追加し、`http://YOUR_PC_IP:8787/clipboard/text` を入力します。
2. アクション「URL の内容を取得」を追加します。
3. 「方法」を `GET` にします。
4. 「ヘッダ」に `X-API-Key: YOUR_API_TOKEN` を追加します。
5. 返ってきた JSON から「辞書の値を取得」でキー `text` を取り出します。
6. アクション「クリップボードにコピー」で `text` をコピーします。

### iPhone の画像を Windows に送る

1. アクション「写真を選択」または「最新の写真を取得」を追加します。
2. アクション「URL」を追加し、`http://YOUR_PC_IP:8787/clipboard/image` を入力します。
3. アクション「URL の内容を取得」を追加します。
4. 「方法」を `POST` にします。
5. 「ヘッダ」に `X-API-Key: YOUR_API_TOKEN` を追加します。
6. 「要求本文」を `フォーム` にします。
7. フォームのフィールド名を `file`、値を手順1の画像にします。

送信された画像は Windows 側の `uploads/images` に保存されます。

### Windows の最新画像を iPhone に取り込む

1. アクション「URL」を追加し、`http://YOUR_PC_IP:8787/clipboard/image/latest` を入力します。
2. アクション「URL の内容を取得」を追加します。
3. 「方法」を `GET` にします。
4. 「ヘッダ」に `X-API-Key: YOUR_API_TOKEN` を追加します。
5. 必要に応じて「写真アルバムに保存」や「共有」へ渡します。

### iPhone のファイルを Windows に送る

1. アクション「ファイルを選択」を追加します。
2. アクション「URL」を追加し、`http://YOUR_PC_IP:8787/clipboard/file` を入力します。
3. アクション「URL の内容を取得」を追加します。
4. 「方法」を `POST` にします。
5. 「ヘッダ」に `X-API-Key: YOUR_API_TOKEN` を追加します。
6. 「要求本文」を `フォーム` にします。
7. フォームのフィールド名を `file`、値を手順1のファイルにします。

送信されたファイルは Windows 側の `uploads/files` に保存されます。

### Windows の最新ファイルを iPhone に取り込む

1. アクション「URL」を追加し、`http://YOUR_PC_IP:8787/clipboard/file/latest` を入力します。
2. アクション「URL の内容を取得」を追加します。
3. 「方法」を `GET` にします。
4. 「ヘッダ」に `X-API-Key: YOUR_API_TOKEN` を追加します。
5. 必要に応じて「ファイルを保存」や「共有」へ渡します。

## Windows ファイアウォールで 8787 番ポートを許可する

iPhone から接続できない場合は、Windows ファイアウォールで TCP 8787 番ポートを許可してください。

管理者として開いた PowerShell またはコマンドプロンプトで、プロジェクトディレクトリに移動して次を実行します。

```bat
allow-firewall.bat
```

手動で設定する場合は、管理者権限の PowerShell で次を実行します。

```powershell
New-NetFirewallRule `
  -DisplayName "Clipboard Sync API 8787" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 8787 `
  -Action Allow
```

## 動作テスト

サーバーを起動したまま、別の PowerShell またはコマンドプロンプトで次を実行します。

```bat
test-api.bat
```

`Clipboard Sync API test passed.` と表示されれば、テキスト・画像・ファイルの基本APIと API キー認証は動作しています。

## セキュリティと保存仕様

- このアプリは LAN 内で使う想定です。インターネットへ直接公開しないでください。
- アップロードファイル名は `YYYYMMDDTHHMMSSffffffZ_元ファイル名` の形式で保存し、衝突を避けます。
- `uploads/` 配下に残すファイルは画像・ファイル合計で最大5件です。6件以上になると古いものから削除します。
- ファイル名はベース名だけを使い、危険な文字を `_` に置換します。
- 保存先が `uploads/images` または `uploads/files` の直下から外れないように検証し、パストラバーサルを防ぎます。
- Windows クリップボードへの画像/ファイル登録は環境依存です。失敗してもアップロード保存と latest API は利用できます。

