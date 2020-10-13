AXI-Stream Video Test Pattern Sender
====================================

このリポジトリには、ACRi ブログでのコース (連載) の1つである「AXI でプロセッサとつながる IP コアを作る」の第2回～第3回で使用したソースコードの一式が含まれています。

システムを完成させるためには、<a href="https://github.com/Digilent/vivado-library/">Digilent 社の IP コアライブラリ</a>内にある rgb2dvi IP コア (ip/rgb2dvi) と TMDS インタフェース定義 (if/tmds) がそれぞれ必要です。これら2つを、このファイルのあるディレクトリにフォルダごとコピーし、このファイルのあるディレクトリを Vivado のプロジェクト設定で IP Repository に指定してください。

詳細は、同コースの記事を確認してください。ACRi ブログへの掲載後に各記事へのリンクを追加します。

ディレクトリ構造は以下のとおりです。

- sender: IP コア一式
  - hdl: 設計ファイル (Verilog HDL, SystemVerilog) 一式
  - testbench: テストベンチ (SystemVerilog)
  - xgui: GUI 設定画面の定義 (Vivado で自動生成)
  - component.xml: IP コアの定義 (Vivado で自動生成)
- Arty_Pynq.xdc: 制約ファイル (Arty Z7-20, PYNQ-Z1 共通)
- init.c: 各種 IP コアを初期化するためのソフトウェア
- LICENSE.txt: ライセンス文
- README.md: このファイル