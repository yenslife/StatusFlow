# StatusFlow 狀態列

一個給在家工作者使用的原生 macOS Menu Bar App，用來明確區分「工作、休息、學習」三種狀態。

## 功能

- Menu Bar 顯示目前狀態與累計時間
- 工作、休息、學習一鍵切換
- 今日各狀態時間統計
- App 內建最近 7 天報告與長條圖
- 可移動、永遠置頂的半透明懸浮膠囊
- 可在設定中調整懸浮視窗的透明度與大小
- 狀態紀錄僅儲存在本機
- 關閉再開啟後接續目前狀態

## 執行方式

1. 使用 macOS 14 或更新版本。
2. 安裝 Xcode 15 或更新版本。
3. 在 Finder 中雙擊 `Package.swift`，或在 Xcode 選擇 **File → Open** 後開啟 `StatusFlow` 資料夾。
4. Scheme 選擇 `StatusFlow`，執行目的地選擇 **My Mac**。
5. 按 `⌘R` 執行。

這是 Menu Bar App，啟動後不會出現在 Dock；請從畫面右上方選單列操作。

## 本機資料位置

`~/.StatusFlow/sessions.json`

程式會自動建立尚不存在的資料夾。如果電腦上已有前兩版的紀錄，第一次啟動新版時會依序檢查：

- `~/SideProject/StatusFlow/data/sessions.json`
- `~/Library/Application Support/StatusFlow/sessions.json`

找到後會自動讀取並寫入新位置。

## 下一版建議

- 自訂番茄鐘與通知
- CSV 匯出
- 登入時自動啟動
