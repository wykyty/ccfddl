# 第三方代码声明 / Third-party notices

## Liquid glass backdrop

`package/contents/ui/components/LiquidGlass.qml`、`MacOSColors.qml`、
`package/contents/ui/components/shaders/*.frag(.qsb)` 以及
`package/contents/ui/config/SliderField.qml` 修改自
**Liquid Glass — macOS Widgets for KDE**（作者 Jack Faith / jaxparrow07）：

- 仓库：https://github.com/jaxparrow07/liquidglass-kde-widgets
- 许可证：GPL-3.0（见仓库根目录 LICENSE）

感谢原作者开源这套精美的液态玻璃实现。

## 会议数据

会议截止数据来自 **CCFDDL**（https://ccfddl.com/ ，数据仓库
ccfddl/ccf-deadlines），通过 `https://ccfddl.com/conference/initial.json`
公开接口获取；`package/contents/data/snapshot.js` 为该数据的一份本地快照，
仅用于断网时的兜底显示。

## 字体

本组件不捆绑任何商业字体，使用系统默认无衬线字体渲染。
