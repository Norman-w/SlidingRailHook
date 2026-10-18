# 12 个滑轨挂钩 · PETG 打印项目 v1

交付文件：`hook-12-PETG-X1C-0p4-0p12.3mf`。

这是 Bambu Studio 原生**已切片项目 3MF**，包含模型、12 件排版、机器/材料/工艺配置及实际 G-code；不是把 STL 打包改后缀。仅含 12 个一体式滑块挂钩，不含导轨或端塞。没有发送打印任务。

## 排版与表面取舍

采用侧放：原模型绕 Y 轴旋转 +90°，再平移落床。钩子的弯曲轮廓落在打印床 XY 平面，减少曲面阶梯；支撑主要接触一侧边面，避开滑槽配合面和钩子朝人的正面。相邻零件包围盒间隔 12 mm，按 4 × 3 排在同一张 256 × 256 mm 板上。

比较了 15 种摆放方向；再在 0.12 mm 层高下比较树状、普通与 Snug 紧贴支撑。所测方案中选择**普通自动支撑 + Snug 紧贴式 + 仅从热床生成**。同侧放、同层高下，单件支撑估算从树状的 0.437 g 降到 0.218 g，约减少一半。不是对所有参数组合的全局最优证明。

不能同时承诺“零支撑痕”和“最少耗材”：这版优先把支撑移出关键表面；侧面支撑接触处仍可能需要轻修。0.12 mm 层高也不等于没有层纹。

## 已保存配置

| 项目 | 设置 |
| --- | --- |
| 机器 / 喷嘴 | Bambu Lab X1 Carbon / 0.4 mm |
| 材料 | Generic PETG，单材料 |
| 打印板 | Textured PEI Plate，65°C |
| 喷嘴温度 | 255°C |
| 层高 / 首层 | 0.12 / 0.20 mm |
| 外墙速度 | 30 mm/s |
| 壁数 / 填充 | 3 圈 / 12% Gyroid |
| 支撑 | 普通自动，Snug，仅从热床生成 |
| 支撑顶/底 Z 间隙 | 0.24 / 0.24 mm |
| 支撑 XY 间隙 | 0.40 mm |
| 顶部接触层 | 3 层，间距 0.30 mm |
| Brim | 仅外侧 2 mm，与模型间隙 0.15 mm |

这是通用 PETG 配置；如料卷标注温度或材料类型不同，应调整后重新切片。没有替用户校准流量、压力提前、材料干燥状态或实际配合公差。

## 整板切片估算

- 总耗材：**16.6 g**。
- 打印时间：**2 小时 33 分 16 秒**。
- 其中支撑及接触层约 **2.623 g**，由实际 G-code 挤出量计算，包含在总耗材内。
- 估算不是实物称重或计时结果；打印机实际校准、启停与清理可能产生差异。

## 验证与剩余门槛

`plate-validation.json` 记录源哈希、各件包围盒、单位/数量、3MF 校验和及实际支撑路径检查。已通过：12 个无缩放、无重叠、未越界的副本；每件封闭、法线一致、无退化面；Bambu Studio CLI 独立重新打开后全部显示 manifold=yes、单一实体。切片警告为空。

支撑验收读取实际普通支撑和接触层 G-code，包含 G2/G3 圆弧，按不大于 0.25 mm / 5°细分后检查端点与中点。未发现滑槽内侧或钩子正面接触样本。这是网格邻近抽样检查，不是实际拆支撑试验。

`toolpaths-review.png` 是从实际 G-code 独立绘制的整板俯视和单件等轴路径图，**不是原生切片器截图**。蓝色为零件、绿色为支撑、金色为接触层、灰色为 Brim。

本机图形切片器已尝试打开项目，但窗口读取超时，**原生 GUI 切片预览验收仍待确认**。打印前请在 Bambu Studio 打开此 3MF，核对 X1C / PETG / 实际打印板、12 个零件和支撑预览，再自行发送打印。实际表面、滑动配合和承载测试尚未进行，建议先试装再正式承重。

## 来源与复现

CAD 来源提交：`8c50913f0cba1a14245644626fdce696a7063f43`，入口 `src/slider_hook.scad` 的 `step_geometry()` 与 `hook_bent_geometry()` 顶层并集。没有修改 CAD 尺寸和圆角。

旋转后的 float32 STL 有 8 个因顶点重合而面积严格为零的三角面。排版前仅移除这些零面积面，不进行补洞、缩放或重塑；体积变化约 1.14e-13 mm³，最终网格到源网格最大顶点偏差小于 0.000003 mm。详情见 `mesh-normalization.json`。

脚本位于 `src/scripts/build_hook_plate.py`、`inspect_hook_plate.py` 与 `preview_hook_toolpaths.py`。使用 `requirements-print.txt` 安装检查依赖，系统需要本机 OpenSCAD 和 Bambu Studio。完整配置 JSON 保存在 `config/`。

```sh
python src/scripts/build_hook_plate.py prepare
python src/scripts/build_hook_plate.py compare
python src/scripts/build_hook_plate.py quality
python src/scripts/build_hook_plate.py final
/Applications/BambuStudio.app/Contents/MacOS/BambuStudio --info output/print-12-v1/hook-12-PETG-X1C-0p4-0p12.3mf > output/print-12-v1/reopen-native.log 2>&1
python src/scripts/inspect_hook_plate.py output/print-12-v1 --verify-plate
```

历史公开发布的 v0.1.0 模型包未被覆盖；本打印项目与历史模型分目录保留。试验 STL / 切片结果、独立 G-code 和大型中间 SVG 仅作本机缓存，不纳入提交；生成脚本与比较摘要保留在仓库，可按上述步骤重新生成。
