# Agent.md

## 目的

このエージェントは、`Setting.md` に定義された架空のソフトウェア企業を前提として、  
営業活動の分析・デモに利用できる **高品質なBI用テストデータ** を、SQLite データベース向けに生成する。

> ⚠️ 企業・組織構造・商談フェーズ・失注理由などの設定は、すべて `Setting.md` に記載されている。  
> データ生成時は、必ず `Setting.md` の内容を参照し、一貫した世界観と整合性を保つこと。

## データ生成のゴール

- Salesforce をイメージしたスキーマに基づき、以下のテーブルに対して整合性のあるテストデータを生成する。
  - `Department`
  - `User`
  - `Account`
  - `Contact`
  - `Product`
  - `Opportunity`
  - `OpportunityItem`
  - `OpportunitySnapshot`
  - `OpportunityHistory`
- 営業部門・サポート部門の組織構造、商談フェーズ、新規/更新別の受注率、失注理由などが  
  BI（Power BI / Tableau）の分析デモとして説得力のある形で再現されていること。

## 前提・制約

- データベースは **SQLite** を想定する。
- テーブル定義・企業設定・ビジネスルールは `Setting.md` を正とし、それに矛盾するデータを生成しない。
- 主キー・外部キー・NOT NULL・ユニーク制約などの整合性を満たすデータのみを出力する。
- 新規・更新の商談について、集計レベルで以下の受注率に近づくようにデータを構成する。
  - 新規商談: 受注率 ≒ 20%
  - 更新商談: 受注率 ≒ 85%
- 商談のフェーズ（Stage）は `Setting.md` に記載された段階・確度に従う。
- 失注した商談には、`Setting.md` で定義された失注理由を **`;` 区切りの複数選択形式** で設定する。

## 出力の基本方針

- 原則として、SQLite 向けの **DDL（CREATE TABLE）** または **INSERT文** を出力する。
- 一度に大量のデータを生成する場合は、INSERT文をバッチに分けて出力してもよい。
- `OpportunitySnapshot` や `OpportunityHistory` など履歴系テーブルは、  
  `Opportunity` の内容と矛盾しないよう、変更日付や値の推移を一貫させる。

## 品質に関する指針

- BI分析でよく使われる切り口（部署・チーム・担当者・プロダクト・新規/更新・期間など）について、
  ある程度のばらつきと偏りがあり、「それっぽい」洞察が得られるようなデータ分布を意識する。
- 極端にきれいすぎるデータ（例: きっちり均等な分布、毎月全く同じ件数 など）は避け、
  現実的なノイズや季節性のニュアンスを少し含めてもよい（ただし `Setting.md` の制約は守る）。

## フェーズ遷移の確率と標準的な滞留期間

- 新規商談（7段階）
  - Prospecting → Qualification: **60% / 7〜10日**
  - Qualification → Needs Analysis: **65% / 7〜12日**
  - Needs Analysis → Proposal: **70% / 10〜14日**
  - Proposal → Negotiation: **60% / 10〜18日**
  - Negotiation → Verbal Commit: **55% / 10〜18日**
  - Verbal Commit → Closed Won: **70% / 7〜14日**
  - いずれの段階でも **10〜20% 程度** は Closed Lost に落ちる想定でノイズを入れる。

- 更新商談（3段階）
  - Upcoming Renewal → Renewal Negotiation: **85% / 14〜21日**
  - Renewal Negotiation → Closed Won: **90% / 10〜18日**
  - 各段階で **5〜10%** を目安に Closed Lost へ遷移させ、更新の高い受注率を維持する。
