# SlidingRailHook Prototype — step + rounded hook R5 + four concave root fillets

这是一个面向 FDM 原型验证的参数化滑轨 step/carriage 系统。当前有效交付包含滑轨、step 滑块、240° 参数化弯钩和左右端挡块；旧 300° bent hook、旧 J-hook 与旧平面梯形板均只作为历史恢复源保留。所有尺寸按毫米解释；STL 本身不携带单位。

## 机械契约与坐标系

- 工艺假设：通用 FDM 原型；未针对具体喷嘴、层高、材料、打印方向或切片参数校准。
- 坐标系：X 沿轨道长度方向（300 mm）；Y 是轨道截面宽度方向；Z 是柜门法向，贴装面为 Z=0。
- 轨道截面是“贴装基底 + 中央腹板 + 靠人侧翼缘”的明确近似，不是标准钢结构 I 型材；轨道目标深度为 5.8 mm，高度为 12 mm。
- step 沿 X 从轨道端部推入/取出。它保留开口底部车体、上盖、两侧壁和两个连续捕获下唇；中央腹板两侧各保留 `0.30 mm` 横向让位。
- 弯钩根部/尾部 X 宽保持 `9.00 / 4.50 mm`，板厚保持 `3.00 mm`；从根部沿原 `20 mm` 参考长度量，`3/5` 处进入弯曲，因此根部到弯曲起点保留 `20×3/5=12.00 mm` 直段。
- 弯曲在 Y-Z 平面沿现有负 Y 挂钩方向延伸，总角度为 `240°`，中心线半径为 `5.00 mm`；按板厚自然形成名义内半径 `3.50 mm`、外半径 `6.50 mm`，末端朝向和钩口开口方向保持不变。
- 弧线圆心位于根部 `+Z` 人侧，弧线从直段末端以 `-Y` 切向连续进入并远离 Z=0 门/墙安装面；弧线实体不侵入 H 槽滑动包络。
- 根部仍位于 `y=1.30`，穿入 step 外侧壁 `0.30 mm` 形成真实正体积重叠；根部 z 范围为 `1.70..4.70`，低于 rail flange 起始面 `z=4.80`，并避开 rail-facing cavity、中央腹板和翼缘运动包络。
- 根部保留 `2.00 mm` 的完整矩形焊接/一体固定区；随后用 `2.00 mm` 连续过渡进入外露圆角扫掠。所有外露截面边使用 `hook_visible_edge_radius=0.75 mm` 的圆角（小于 `3.00/2 mm`）；自由端使用长度/有效圆化半径约 `1.50 mm` 的椭球端帽，并与弧线末端截面实体 hull 桥接，没有切断、间隙、铰接、尖角、大平切面或零厚度颈部。
- Y–Z 截面中，根部 +Z 与 −Z 两处均为 `R1.25 mm` 的凹圆弧胶脚，取代原先方向错误的凸四分之一圆柱。+Z 胶脚同时与基座平面、钩子上表面相切；−Z 胶脚同时与基座原有 `R0.6 mm` 下圆角、钩子下表面相切。后者最低 Z 约 `1.2946 mm`，高于轨道贴装基板的 `1.02 mm` 上界；布尔检查确认与轨道不相交。两胶脚沿 X 覆盖 `9 mm` 根宽，端部用 `0.15 mm` 平滑回收，并保留正体积重叠。
- 装配图中钩根左、右两侧（±X）的 `R1.25 mm` 凹圆弧胶脚维持原样，连接基座外侧面与钩子的渐缩侧面。胶脚沿 Z 覆盖根部厚度，外露上下端用 `0.15 mm` 平滑回收。含胶脚的钩子总 X 包络约 `11.294 mm`，钩子主体根宽仍为 `9.00 mm`。
- 默认滑动间隙由 `slide_clearance=0.30` 控制；端挡块只负责 X 向限位。
- 当前不包含旧 J-hook 的 fairing、root bridge、anchor 或旧多站点 stem/tip；新弯钩仅按上述 240° 圆弧参数生成，也不声称已经完成实物配合或承载验证。

## 源文件

- `src/parameters.scad`：唯一参数源；其中保留了旧 hook 参数命名，以便恢复历史模型和保持尺寸兼容；当前直段为 `12.00 mm`、中心线半径为 `5.00 mm`、端帽长度为 `hook_bent_end_cap_length=1.50 mm`、根部打胶圆角为 `bond_fillet_radius=1.25 mm`。
- `src/rail.scad`：轨道单体。
- `src/step.scad`：当前 active step/carriage 单体，只由车体和 H 形翼缘捕获 lips 构成。
- `src/hook_bent.scad`：当前 active 240° 圆角弯钩单体；焊接区、圆角过渡、直段长度、中心线半径、弯曲角度、板厚和 X 向宽度渐变均参数化。
- `src/hook_trapezoid.scad`：旧平面 9×20×3 版本源文件，保留用于恢复和对比，不再被 active assembly 或导出脚本引用。
- `src/end_stop.scad`：端挡块；用 `end_stop_part="left"` 或 `"right"` 选择左右件。
- `src/assembly.scad`：轨道 + step + 240° 弯钩 + 左右端挡块的预览装配，不作为打印件。
- `src/hook.scad`：旧 J-hook 源码，保留用于恢复和对比，但不再被 active assembly 或导出脚本引用。

## 导出与检查

```sh
./src/scripts/export_parts.sh
```

当前 active 导出目标只有：

- `output/3d-print/rail.stl`
- `output/3d-print/step.stl`
- `output/3d-print/hook_bent.stl`
- `output/3d-print/end_stop_left.stl`
- `output/3d-print/end_stop_right.stl`

脚本会使用 OpenSCAD CLI 导出，并用 `inspect_stl.py --require-watertight` 检查五个 STL；原始报告保存在 `output/reports/`。旧 J-hook 与旧平面梯形 STL 会保存在 `output/3d-print/history/`，不进入 active manifest。

## 预览与截面

当前 HTTP 预览清单位于 `output/3d-preview/manifest.json`，标题为 `SlidingRailHook — R5 +Z + four concave root fillets`，active API 恰好暴露 5 个零件：`rail`、`step`、`hook_bent`、`end_stop_left`、`end_stop_right`。本机预览地址为 `http://127.0.0.1:8765/`；页面只用于观看，不替代尺寸、拓扑和实物配合验证。

新渲染位于 `output/renders/step-only/`：

- `step.png`：step 单体。
- `hook-bent.png` / `hook-bent-side.png`：240° 圆角弯钩单色等轴/侧视图。
- `hook-bent-root-fillet.png`：根部装配局部图，显示钩根左、右两侧与基座相接的胶脚。
- `root-left-right-plan.png`：通过根部中面的 XY 截面，直接显示两侧凹角被圆弧填充。
- `root-yz-section-axes.png`：Y–Z 根部局部截面，显示 +Z 与 −Z 两处相切凹圆角，带坐标轴。
- `assembly-isometric-axes.png`：当前装配等轴视图，带 X/Y/Z 坐标轴。
- `rail-step-bent-assembly-iso.png`：轨道 + step + 240° 弯钩 + 端挡块装配。
- `rail-step-bent-h-section.png`：H 形捕获与弯钩根部截面，确认 0.30 mm 间隙和根部连接。
- `hook-bent-section.png`：弯钩局部剖面预览。

旧 hook 渲染和装配图保存在 `output/renders/history-hook-2026-10-17/`；旧平面梯形渲染保存在 `output/renders/history-hook-trapezoid-flat-2026-10-18/`；旧 300° bent 渲染保存在 `output/renders/history-hook-bent-300deg-2026-10-18/`；未圆化240° STL保存在 `output/3d-print/history/hook_bent-240deg-unrounded-pre-edge-round-2026-10-18.stl`，对应预览保存在 `output/renders/history-hook-bent-240deg-unrounded-2026-10-18/`；上一版0.75 mm端帽保存在 `output/3d-print/history/hook_bent-240deg-rounded-0p75-endcap-pre-full-round-2026-10-18.stl`，对应预览保存在 `output/renders/history-hook-bent-240deg-rounded-0p75-endcap-2026-10-18/`；上一版 R3 圆角弯钩保存在 `output/3d-print/history/hook_bent-240deg-R3-rounded-endcap1p5-pre-R5-2026-10-18.stl`，对应预览保存在 `output/renders/history-hook-bent-240deg-R3-rounded-endcap1p5-2026-10-18/`；上一版反向 -Z R5 弯钩保存在 `output/3d-print/history/hook_bent-240deg-R5-negative-Z-pre-positive-Z-2026-10-18.stl`，对应预览保存在 `output/renders/history-hook-bent-240deg-R5-negative-Z-2026-10-18/`；上一版正向 R5 无打胶圆角弯钩保存在 `output/3d-print/history/hook_bent-240deg-R5-positive-Z-pre-bond-fillet-2026-10-18.stl`，对应预览保存在 `output/renders/history-hook-bent-240deg-R5-positive-Z-no-bond-fillet-2026-10-18/`；历史 STL 也集中保存在 `output/3d-print/history/`。它们均可恢复，但不属于当前交付。

## 当前限制

本项目只输出源 SCAD 和可验证 STL；不替用户决定胶带/螺钉/粘接方案，也不声称满足具体材料的额定载荷。首件打印前不得把名义 `0.30 mm` 间隙、端挡块配合、打印强度或实际安装方式视为已验证。
