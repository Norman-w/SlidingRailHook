# SlidingRailHook · 滑动首饰挂钩

用于柜门/梳妆台的参数化 H 形滑轨与一体式滑块挂钩，使用 OpenSCAD 建模。

![带 XYZ 坐标轴的等轴装配图](output/releases/v0.1.0/renders/assembly-isometric-axes.png)

## v0.1.0：根部四角连续补胶

补齐钩子根部 ±X、−Y 与 ±Z 三面交汇处原先的缺口。原有四条 R1.25 凹圆角不再各自收尾，而是通过四块连续转角曲面衔接；转角实体与基座、钩子以及相邻两条胶脚均有正体积重叠。

钩子与滑块属于一体打印件。这里的“焊接”“打胶”是连续实体圆角，不是真实胶水，也不需要把两个 STL 粘起来。

- [最新公开发布与下载](https://github.com/Norman-w/SlidingRailHook/releases/latest)
- [几何验证报告](output/releases/v0.1.0/reports/validation.json)
- [根部等轴近景](output/releases/v0.1.0/renders/root-isometric-axes.png)
- [根部背侧近景](output/releases/v0.1.0/renders/root-underside-axes.png)

## 打印件

| 文件 | 说明 |
|---|---|
| `rail.stl` | 300 mm 轨道，柜门贴装面为 Z=0 |
| `slider_hook.stl` | **合并后的滑块＋挂钩，一体打印**；按需要打印多个 |
| `end_stop_left.stl` | 左端挡块 |
| `end_stop_right.stl` | 右端挡块 |

当前文件均在 `output/releases/v0.1.0/stl/`，也作为 Release 附件提供。`output/3d-print/`、`output/versions/` 与 `docs/prototype-history.md` 是历史开发记录，不要把旧 `step.stl` 和 `hook_bent.stl` 当作当前的一体打印件。

## 尺寸与装配契约

- 单位：mm。X 沿轨道，Y 向上，Z 为柜门法向；+Z 靠人，挂钩沿 −Y 下垂。
- 轨道：长 300、高 12、总深 5.8；基板、腹板、前翼缘名义壁厚 1。
- 从轨道端部沿 X 插入滑块，随后安装端挡块。不要从前方硬掰卡入。
- 名义滑动间隙 0.30；补胶保持在外侧根部，不侵入滑动槽。
- 钩身根宽/尾宽 9/4.5、厚 3、直段 12；在 Y–Z 平面向 +Z 弯曲 240°，中心线半径 5。
- 外露截面圆角 0.75，末端椭球端帽长 1.5；根部保留 2 mm 完整连接区。
- 根部四条凹圆角名义 R1.25；下侧适配基座原有 R0.6 圆角，不向门侧基板乱填实体。

尺寸唯一来源是 `src/parameters.scad`。`src/slider_hook.scad` 是一体件导出入口；`src/assembly.scad` 是装配预览入口。单独的 step/hook 模块仅用于设计与诊断。

## 从源码重新生成

需要支持 CGAL 后端的 OpenSCAD，以及 Python 3.12+。以下命令只导出和验证，不连接打印机：

```sh
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-qa.txt
sh src/scripts/export_parts.sh
```

默认输出到 `output/build/`。也可以指定一个新的输出目录：

```sh
sh src/scripts/export_parts.sh output/my-build
```

脚本用原生 CGAL 导出 STL，再用 trimesh 检查封闭拓扑、法线、单一连通实体，并用 manifold3d 检查四角正体积连接、完整填充及轨道多位置干涉。`reports/` 内的角块、基座、焊接段等 STL 是诊断体，**不属于打印清单**。

## 验证边界

这是 FDM 原型，尚未做指定材料、喷嘴和层高的切片或实物承载测试。0.30 mm 间隙仍须打印试配；一毫米薄壁、胶带/粘接固定、端挡块保持力、首层、支撑和长期耐久需实际确认。轨道为 300 mm 单件，请先确认打印床能够容纳。

公开仓库和下载文件不代表额定承载、安全认证或实物配合已经通过。
