#  <环境 ： xcode: 10.1>

>  PacketProcessor 静态库引入后报错：
1. 添加预编译宏：Preprocessor Macro
2. build settings Search Paths: User header search paths
3. build phases: headers
4. build phases: link with libraries


>  shadowPath 工程导入后
在File > Project/Workspace Settings中的Share Project/Workspace Settings 里build system 将New Build System(Default)切换成Legacy build system。
如果 shadowPath.framework 是红色的 那么选中这个库运行下
tunnel Linked Frameworkd and Libraryes 加入shadowPath.framework
tunnel 扩展的 Enable BitCode 改为NO
 
 
 
 //carthage
 https://www.cnblogs.com/shenhongbang/p/5526614.html
