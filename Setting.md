# Setting.md

## 1. 企業の概要

- 業種: ソフトウェアを開発・販売する会社（SaaS/ソフトウェアライセンスビジネスを想定）
- データソース: Salesforce をイメージした構造
- 主な部門:
  - 営業部門
  - ソフトウェアサポート部門

### 1.1 営業部門の構成

- 営業部門には **3つのディビジョン（division）** が存在する想定とする。
  - 例: 「営業第1ディビジョン」「営業第2ディビジョン」「エンタープライズ営業」など
- 各ディビジョンの中に **2〜3チーム** が存在する。
- `Department` テーブルの 1 レコードが **1チーム** に対応する。
  - `Department.name`: チーム名（例: "第1ディビジョン_チームA"）
  - `Department.division_name`: ディビジョン名
- 各チームには **5〜7名** の営業担当（User）が所属する。
- 営業担当は主に以下の種類の商談を扱う。
  - 新規（New Business）
  - 更新（Renewal）

### 1.2 ソフトウェアサポート部門の構成

- ソフトウェアのサポートを行う部署があり、**5名×2チーム** で構成される。
- サポート部門のチームも `Department` に登録される。
  - `division_name` を「カスタマーサポート」などで統一し、
  - `name` にチーム名（例: "サポート_チーム1"）を設定する。
- サポート部門のメンバーも `User` テーブルで管理する。

---

## 2. 商談（Opportunity）のビジネスルール

### 2.1 商談の種類と受注率

- 商談には「新規」「更新」の2種類が存在する（`Opportunity.Type` などで表現）。
- 集計レベルで、最終的な受注率は以下を目安にする。
  - 新規商談: **約20%**
  - 更新商談: **約85%**

### 2.2 新規商談のフェーズ（7段階）

新規商談は以下の 7 フェーズで管理される。  
`Stage` と `Probability`（確度, %）の一例は次の通り。

> ※ Stage 名に `New` プレフィックスは付けない。

- `Prospecting`（見込み客発掘）: 10%
- `Qualification`（案件化・要件ヒアリング）: 20%
- `Needs Analysis`（課題・要件定義）: 30%
- `Proposal`（提案・見積提示）: 50%
- `Negotiation`（条件交渉・稟議中）: 70%
- `Verbal Commit`（口頭合意・最終調整）: 90%
- `Closed Won`（受注）: 100%

失注した新規商談は、最終的に `Closed Lost` フェーズに遷移させる。  
`Closed Lost` の確度は **0%** として扱う。

### 2.3 更新商談のフェーズ（3段階）

更新商談は、以下の 3 フェーズでシンプルに管理する。

> ※ Stage 名に `Ren` プレフィックスは付けない。

- `Upcoming Renewal`（更新対象抽出・事前接触）: 50%
- `Renewal Negotiation`（更新条件の交渉・調整）: 75%
- `Closed Won`（更新完了）: 100%

更新商談が失注した場合も、`Closed Lost` フェーズに遷移し、確度は **0%** として扱う。

### 2.4 失注理由（複数選択; 区切り文字は `;`）

商談が失注（Closed Lost）した場合、以下の失注理由から **複数選択** する。  
データ上は `;` 区切りの文字列として保存する（例: `"価格が高い;競合製品を選択"`）。

- 価格が高い
- 競合製品を選択
- 機能要件を満たさない
- 予算が確保できなかった
- タイミングが合わなかった（導入時期 延期・中止）
- 社内事情（組織変更・優先度変更など）
- 顧客側の意思決定プロセスが停滞
- 当社サポート／対応への不安

---

## 3. テーブル一覧と概要

このプロジェクトでは、以下のテーブルを前提としてデータを生成する。  
実際のカラム構成や制約は、SQLite 用の DDL で具体化する。

### 3.1 Department

- **1レコード = 1チーム** を表現する。
- ディビジョン名（大きな括り）とチーム名を持つ。

想定フィールド例:

- `id` (PK)
- `name` — チーム名（例: "第1ディビジョン_チームA"）
- `division_name` — ディビジョン名（例: "営業第1ディビジョン"）
- `department_type` — 例: `Sales`, `Support`

### 3.2 User

- 社員・担当者情報を管理。
- 営業とサポートの両方のメンバーを含む。

想定フィールド例:

- `id` (PK)
- `department_id` (FK -> Department)
- `name`
- `email`
- `role`（例: `SalesRep`, `SalesManager`, `SupportEngineer` など）

### 3.3 Account

- 取引先企業（顧客）情報を管理。

想定フィールド例:

- `id` (PK)
- `name`
- `industry`
- `billing_country`
- `billing_city`
- `created_at`

### 3.4 Contact

- 取引先担当者情報を管理。

想定フィールド例:

- `id` (PK)
- `account_id` (FK -> Account)
- `name`
- `title`
- `email`
- `phone`

### 3.5 Product

- 販売しているソフトウェア製品情報を管理。

想定フィールド例:

- `id` (PK)
- `name`
- `category`（例: `Core`, `Addon`, `Service`）
- `unit_price`
- `is_subscription`（サブスクリプションかどうか）
- `default_term_months`（サブスク期間の標準値）

### 3.6 Opportunity

- 商談のヘッダ情報を管理。

想定フィールド例:

- `id` (PK)
- `account_id` (FK -> Account)
- `owner_user_id` (FK -> User)
- `type`（`New` / `Renewal`）
- `stage`（本設定で定義したステージ名: `Prospecting`, `Renewal Negotiation`, `Closed Won` など）
- `amount`
- `close_date`
- `created_date`
- `probability`（ステージに応じた確度）
- `is_closed`
- `is_won`
- `lost_reasons`（失注時のみ; `;` 区切り文字列）

### 3.7 OpportunityItem

- 商談ごとの製品明細。`Opportunity × Product` の中間テーブル。

想定フィールド例:

- `id` (PK)
- `opportunity_id` (FK -> Opportunity)
- `product_id` (FK -> Product)
- `quantity`
- `unit_price`
- `amount`（`quantity * unit_price`）

### 3.8 OpportunitySnapshot

- 商談の週次スナップショット。スナップショット分析用。

想定フィールド例:

- `id` (PK)
- `opportunity_id` (FK -> Opportunity)
- `stage`
- `amount`
- `close_date`
- `probability`
- `is_closed`
- `is_won`
- `snapshot_date`（スナップショットを取得した週の日付）
- `owner_user_id` (FK -> User)

### 3.9 OpportunityHistory

- 商談に対する重要項目の変更履歴を管理。

対象フィールド（例）:

- `Stage`
- `CloseDate`
- `Amount`

想定フィールド例:

- `id` (PK)
- `opportunity_id` (FK -> Opportunity)
- `field`（変更されたフィールド名: `Stage`, `CloseDate`, `Amount` など）
- `old_value`
- `new_value`
- `changed_at`

---

## 4. データ生成時の留意点

- `Department` レコードはチーム単位で作成し、`division_name` により上位のディビジョンを識別する。
- 営業ディビジョンごとに 2〜3チーム、1チーム5〜7名程度の営業担当を `User` として生成する。
- 新規/更新比率・受注率・フェーズ分布が、BIで分析した際に「現実的に見える」ように調整する。
- サポート部門のユーザーは商談を持たないが、将来的な拡張（サポートケースなど）に備えておく想定とする。
