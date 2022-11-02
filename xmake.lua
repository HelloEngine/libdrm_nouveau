add_rules("mode.debug", "mode.release")
set_plat("cross")
--set_version("master")
toolchain("aarch64-none-elf")
    set_kind("cross")
    on_load(function (toolchain)
        toolchain:load_cross_toolchain()
    end)
toolchain_end()

add_repositories("xswitch-repo https://github.com/HelloEngine/xswitch-repo.git main")
add_requires("devkit-a64", "libnx")
target("drm_nouveau")
    set_policy("check.auto_ignore_flags", false)
    if is_mode("debug") then
        set_basename("drm_nouveaud")
    else
        set_basename("drm_nouveau")
    end
    set_toolchains("aarch64-none-elf@devkit-a64")
    set_kind("static")
    add_packages("libnx")

    add_files("source/**.c")
    add_includedirs("include")

    on_load(function(target)
        assert(is_plat("cross"))
        assert(is_host("windows") or is_subhost("msys"))

        local arch = {
            "-march=armv8-a", 
            "-mtune=cortex-a57", 
            "-mtp=soft", 
            "-fPIE",
            "-ftls-model=local-exec",
            "-MMD", "-MP", "-MF"
        }
        local cflags = {
            "-g", 
            "-Wall", 
            "-Werror",
            "-ffunction-sections",
            "-fdata-sections",
            table.unpack(arch)
        }
        local cxxflags = {
            "-fno-rtti",
            "-fno-exceptions", 
            "-std=gnu++11",
            table.unpack(cflags)
        }
        local asflags = {
            "-g", 
            table.unpack(arch)
        }

        target:add("cxxflags", table.unpack(cxxflags))
        target:add("cflags", table.unpack(cflags))
        target:add("asflags", table.unpack(asflags))
        target:add("defines", "__SWITCH__")

        if is_mode("debug") then
            target:add("cflags", "-DDEBUG=1", "-Og")
            target:add("cxxflags", "-DDEBUG=1", "-Og")
        else
            target:add("cflags", "-DDEBUG=1", "-O2")
            target:add("cxxflags", "-DDEBUG=1", "-O2")
        end
    end)

    on_install(function(target)
        os.cp(target:targetfile(), target:installdir() .. "/lib/")
        os.cp(target:scriptdir() .. "/include", target:installdir())
    end)

    on_package(function(target)
        local packagedir = "$(buildir)/packages/" .. target:name() .. "/"
        os.cp(target:targetdir(), packagedir .. "/lib/")
        os.cp(target:scriptdir() .. "/include", packagedir)

        io.writefile(packagedir .. "/xmake.lua", [[
package("drm_nouveau")

    on_load(function(package)
        package:set("installdir", os.scriptdir())
    end)
    
    on_fetch("cross@windows", "cross@msys", function (package)
        local result = {}
        if is_mode("debug") then
            result.linkdirs = package:installdir("lib/debug")
            result.links = "drm_nouveaud"
        else
            result.linkdirs = package:installdir("lib/release")
            result.links = "drm_nouveau"
        end
        result.includedirs = package:installdir("include")
        return result
    end)
package_end()
        ]])
    end)