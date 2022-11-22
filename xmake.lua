add_rules("mode.debug", "mode.release")
set_allowedplats("cross")

add_repositories("xswitch-repo https://github.com/HelloEngine/xswitch-repo.git main")
add_requires("devkit-a64", "libnx")
target("drm_nouveau")
    if is_mode("debug") then
        set_basename("drm_nouveaud")
    else
        set_basename("drm_nouveau")
    end
    set_toolchains("cross@devkit-a64")
    set_kind("static")
    add_packages("devkit-a64", "libnx")
    add_rules("@devkit-a64/aarch64")
    add_files("source/**.c")
    add_includedirs("include")

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