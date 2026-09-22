#!/usr/bin/env python3
"""Write a signing-disabled iOS app project for Meine."""
from pathlib import Path

root = Path("/var/minis/workspace/Meine")
core = sorted(p.name for p in (root / "Sources/MeineCore").glob("*.swift"))
app = sorted(p.name for p in (root / "MeineApp").glob("*.swift"))

def uid(prefix, name):
    number = abs(hash(name)) % 10**8
    return f"{prefix}{number:08d}".replace("0", "A")

lines = []
def add(s=""):
    lines.append(s)

add("// !$*UTF8*$!")
add("{")
add("\tarchiveVersion = 1;")
add("\tclasses = {};")
add("\tobjectVersion = 56;")
add("\tobjects = {")

refs = {}
for name in core:
    refs[name] = uid("C", name)
    add(f"\t\t{refs[name]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
for name in app:
    refs[name] = uid("A", name)
    add(f"\t\t{refs[name]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
add('\t\tINF0 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };')
add('\t\tAST1 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };')
add('\t\tAPP0 /* Meine.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Meine.app; sourceTree = BUILT_PRODUCTS_DIR; };')
frameworks = [
    ("AVFoundation", "AVFoundation.framework"),
    ("AVKit", "AVKit.framework"),
    ("MediaPlayer", "MediaPlayer.framework"),
    ("CryptoKit", "CryptoKit.framework"),
]
for name, path in frameworks:
    add(f'\t\tF{name[:3].upper()} /* {path} */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = {path}; path = System/Library/Frameworks/{path}; sourceTree = SDKROOT; }};')
    add(f'\t\tL{name[:3].upper()} /* {path} in Frameworks */ = {{isa = PBXBuildFile; fileRef = F{name[:3].upper()}; }};')

builds = {}
for name in core + app:
    builds[name] = uid("B", name)
    add(f"\t\t{builds[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {refs[name]}; }};")

core_children = ", ".join(refs[n] for n in core)
app_children = ", ".join(refs[n] for n in app) + ", INF0, AST1"
add(f"\t\tGCORE /* MeineCore */ = {{isa = PBXGroup; children = ({core_children}); path = Sources/MeineCore; sourceTree = \"<group>\"; }};")
add(f"\t\tGAPP /* MeineApp */ = {{isa = PBXGroup; children = ({app_children}); path = MeineApp; sourceTree = \"<group>\"; }};")
add('\t\tGFRM /* Frameworks */ = {isa = PBXGroup; children = (FAVF, FAVK, FMED, FCRY); name = Frameworks; sourceTree = "<group>"; };')
add('\t\tGROOT /* */ = {isa = PBXGroup; children = (GCORE, GAPP, GFRM, APP0); sourceTree = "<group>"; };')

file_list = ", ".join(builds[n] for n in core + app)
add(f"\t\tSRC1 /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({file_list}); runOnlyForDeploymentPostprocessing = 0; }};")
add("\t\tRES1 /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (RAST); runOnlyForDeploymentPostprocessing = 0; };")
add("\t\tRAST /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = AST1; };")
add("\t\tFRM1 /* Frameworks */ = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (LAVF, LAVK, LMED, LCRY); runOnlyForDeploymentPostprocessing = 0; };")

target_settings = {
    "CODE_SIGNING_ALLOWED": "NO",
    "CODE_SIGN_IDENTITY": '""',
    "CODE_SIGNING_REQUIRED": "NO",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "MeineApp/Info.plist",
    "CODE_SIGN_ENTITLEMENTS": '""',
    "ENABLE_PREVIEWS": "NO",
    "ENABLE_ON_DEMAND_RESOURCES": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOLS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "NO",
    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
    "COMPILER_INDEX_STORE_ENABLE": "NO",
    "PRODUCT_BUNDLE_IDENTIFIER": "local.meine.app",
    "PRODUCT_NAME": "Meine",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "SDKROOT": "iphoneos",
    "TARGETED_DEVICE_FAMILY": '"1,2"',
    "SWIFT_VERSION": "5.0",
    "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks"',
    "ENABLE_PREVIEWS": "NO",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
}

def settings_block(name, extra):
    body = " ".join(f"{k} = {v};" for k, v in extra.items())
    return f"\t\t{name} /* cfg */ = {{isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {name[-3:] and 'Release' if name.endswith('R') else 'Debug'}; }};"

# simpler explicit configs
def cfg(ident, name, pairs):
    add(f"\t\t{ident} /* {name} */ = {{")
    add("\t\t\tisa = XCBuildConfiguration;")
    add("\t\t\tbuildSettings = {")
    for k, v in pairs.items():
        add(f"\t\t\t\t{k} = {v};")
    add("\t\t\t};")
    add(f"\t\t\tname = {name};")
    add("\t\t};")

project_common = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "SDKROOT": "iphoneos",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": '"1,2"',
    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
}
cfg("PDBG", "Debug", project_common)
cfg("PREL", "Release", project_common)
cfg("TDBG", "Debug", target_settings)
cfg("TREL", "Release", target_settings)

add("\t\tLPRJ /* list */ = {isa = XCConfigurationList; buildConfigurations = (PDBG, PREL); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };")
add("\t\tLTGT /* list */ = {isa = XCConfigurationList; buildConfigurations = (TDBG, TREL); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };")
add("\t\tTGT1 /* Meine */ = {isa = PBXNativeTarget; buildConfigurationList = LTGT; buildPhases = (SRC1, FRM1, RES1); buildRules = (); dependencies = (); name = Meine; productName = Meine; productReference = APP0; productType = \"com.apple.product-type.application\"; };")
add("\t\tPRJ1 /* Project object */ = {isa = PBXProject; attributes = {LastUpgradeCheck = 1500; }; buildConfigurationList = LPRJ; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = vi; hasScannedForEncodings = 0; knownRegions = (vi, en); mainGroup = GROOT; productRefGroup = GROOT; projectDirPath = \"\"; projectRoot = \"\"; targets = (TGT1); };")
add("\t};")
add("\trootObject = PRJ1;")
add("}")

out = root / "Meine.xcodeproj" / "project.pbxproj"
out.parent.mkdir(exist_ok=True)
out.write_text("\n".join(lines) + "\n")
print("wrote", out, "files", len(core) + len(app))
