"""Generate a deterministic Xcode project with no third-party dependencies."""
from pathlib import Path
import hashlib
import json
import plistlib

ROOT = Path(__file__).resolve().parent.parent
objects = {}


def uid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def obj(identity, isa, **values):
    key = uid(identity)
    objects[key] = dict(isa=isa, **values)
    return key


def encode(value, indent=0):
    pad = "\t" * indent
    if isinstance(value, dict):
        return "{\n" + "".join(f'{pad}\t{json.dumps(k)} = {encode(v, indent+1)};\n' for k, v in value.items()) + pad + "}"
    if isinstance(value, list):
        return "(\n" + "".join(f'{pad}\t{encode(v, indent+1)},\n' for v in value) + pad + ")"
    return json.dumps(str(value), ensure_ascii=False)


def file_ref(path, filetype):
    return obj("file:" + path, "PBXFileReference", lastKnownFileType=filetype, path=path, sourceTree="<group>")


def build_file(path, ref):
    return obj("build:" + path, "PBXBuildFile", fileRef=ref)


sources = []
children = []
for path in sorted((ROOT / "iOS/PlanoDeVida").rglob("*.swift")):
    name = path.relative_to(ROOT).as_posix()
    ref = file_ref(name, "sourcecode.swift")
    children.append(ref)
    sources.append(build_file(name, ref))
resources = []
for path, filetype in [("iOS/PlanoDeVida/Assets.xcassets", "folder.assetcatalog"), ("iOS/PlanoDeVida/PrivacyInfo.xcprivacy", "text.xml")]:
    ref = file_ref(path, filetype); children.append(ref); resources.append(build_file(path, ref))
children.append(file_ref("iOS/PlanoDeVida/Info.plist", "text.plist.xml"))
app_product = obj("app-product", "PBXFileReference", explicitFileType="wrapper.application", path="PlanoDeVida.app", sourceTree="BUILT_PRODUCTS_DIR")
test_product = obj("test-product", "PBXFileReference", explicitFileType="wrapper.cfbundle", path="PlanoDeVidaUITests.xctest", sourceTree="BUILT_PRODUCTS_DIR")
products = obj("products", "PBXGroup", children=[app_product, test_product], name="Products", sourceTree="<group>")
test_path = "iOS/PlanoDeVidaUITests/PlanoDeVidaUITests.swift"
test_ref = file_ref(test_path, "sourcecode.swift"); children.append(test_ref)
main_group = obj("main-group", "PBXGroup", children=children+[products], sourceTree="<group>")
package = obj("package", "XCLocalSwiftPackageReference", relativePath=".")
product_dependency = obj("core-product", "XCSwiftPackageProductDependency", package=package, productName="DevotionalCore")
core_build = obj("core-link", "PBXBuildFile", productRef=product_dependency)
app_sources = obj("app-sources", "PBXSourcesBuildPhase", buildActionMask=2147483647, files=sources, runOnlyForDeploymentPostprocessing=0)
app_resources = obj("app-resources", "PBXResourcesBuildPhase", buildActionMask=2147483647, files=resources, runOnlyForDeploymentPostprocessing=0)
app_frameworks = obj("app-frameworks", "PBXFrameworksBuildPhase", buildActionMask=2147483647, files=[core_build], runOnlyForDeploymentPostprocessing=0)
test_sources = obj("test-sources", "PBXSourcesBuildPhase", buildActionMask=2147483647, files=[build_file(test_path, test_ref)], runOnlyForDeploymentPostprocessing=0)
test_frameworks = obj("test-frameworks", "PBXFrameworksBuildPhase", buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0)


def configs(name, settings):
    configs = []
    for mode in ("Debug", "Release"):
        values = dict(settings)
        values["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone" if mode == "Debug" else "-O"
        values["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) DEBUG" if mode == "Debug" else "$(inherited)"
        values["DEBUG_INFORMATION_FORMAT"] = "dwarf" if mode == "Debug" else "dwarf-with-dsym"
        values["ONLY_ACTIVE_ARCH"] = "YES" if mode == "Debug" else "NO"
        if mode == "Debug": values["ENABLE_TESTABILITY"] = "YES"
        configs.append(obj(name+mode, "XCBuildConfiguration", buildSettings=values, name=mode))
    return obj(name+"configs", "XCConfigurationList", buildConfigurations=configs, defaultConfigurationIsVisible=0, defaultConfigurationName="Release")


project_configs = configs("project", {"SDKROOT": "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET": "17.0", "CLANG_ENABLE_MODULES": "YES", "SWIFT_VERSION": "5.0"})
common = {"PRODUCT_NAME": "$(TARGET_NAME)", "CODE_SIGN_STYLE": "Automatic", "TARGETED_DEVICE_FAMILY": "1", "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator", "SUPPORTS_MACCATALYST": "NO", "SWIFT_VERSION": "5.0", "IPHONEOS_DEPLOYMENT_TARGET": "17.0", "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"]}
app_configs = configs("app", dict(common, PRODUCT_BUNDLE_IDENTIFIER="br.com.marcusalves.planodevida", INFOPLIST_FILE="iOS/PlanoDeVida/Info.plist", GENERATE_INFOPLIST_FILE="NO", ASSETCATALOG_COMPILER_APPICON_NAME="AppIcon", ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME="AccentColor", CURRENT_PROJECT_VERSION="1", MARKETING_VERSION="0.1.0", ENABLE_PREVIEWS="YES"))
test_configs = configs("test", dict(common, PRODUCT_BUNDLE_IDENTIFIER="br.com.marcusalves.planodevida.uitests", GENERATE_INFOPLIST_FILE="YES", TEST_TARGET_NAME="PlanoDeVida"))
app_target = obj("app-target", "PBXNativeTarget", buildConfigurationList=app_configs, buildPhases=[app_sources, app_frameworks, app_resources], buildRules=[], dependencies=[], name="PlanoDeVida", packageProductDependencies=[product_dependency], productName="PlanoDeVida", productReference=app_product, productType="com.apple.product-type.application")
proxy = obj("test-proxy", "PBXContainerItemProxy", containerPortal=uid("project"), proxyType=1, remoteGlobalIDString=app_target, remoteInfo="PlanoDeVida")
dependency = obj("test-dependency", "PBXTargetDependency", target=app_target, targetProxy=proxy)
test_target = obj("test-target", "PBXNativeTarget", buildConfigurationList=test_configs, buildPhases=[test_sources, test_frameworks], buildRules=[], dependencies=[dependency], name="PlanoDeVidaUITests", productName="PlanoDeVidaUITests", productReference=test_product, productType="com.apple.product-type.bundle.ui-testing")
project = obj("project", "PBXProject", attributes={"LastUpgradeCheck": "1600", "BuildIndependentTargetsInParallel": "YES", "TargetAttributes": {app_target: {"CreatedOnToolsVersion": "16.0"}, test_target: {"CreatedOnToolsVersion": "16.0", "TestTargetID": app_target}}}, buildConfigurationList=project_configs, compatibilityVersion="Xcode 14.0", developmentRegion="pt-BR", hasScannedForEncodings=0, knownRegions=["pt-BR", "en", "Base"], mainGroup=main_group, productRefGroup=products, projectDirPath="", projectRoot="", packageReferences=[package], targets=[app_target, test_target])
folder = ROOT / "PlanoDeVida.xcodeproj"
folder.mkdir(exist_ok=True)
(folder / "project.pbxproj").write_text("// !$*UTF8*$!\n" + encode({"archiveVersion": 1, "classes": {}, "objectVersion": 56, "objects": objects, "rootObject": project}) + "\n", encoding="utf-8")
schemes = folder / "xcshareddata/xcschemes"; schemes.mkdir(parents=True, exist_ok=True)


def reference(target, name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:PlanoDeVida.xcodeproj"/>'


(schemes / "PlanoDeVida.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference(app_target, "PlanoDeVida.app")}</BuildActionEntry></BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{reference(test_target, "PlanoDeVidaUITests.xctest")}</TestableReference></Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference(app_target, "PlanoDeVida.app")}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference(app_target, "PlanoDeVida.app")}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''', encoding="utf-8")

for file in (ROOT / "iOS").rglob("*.plist"):
    with file.open("rb") as stream: plistlib.load(stream)
print(f"Generated Xcode project: {len(sources)} app source files, one local package, UI test target.")
