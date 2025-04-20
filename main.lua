getgenv().get_github_file = function(file)
    local user, repo = "uzu01", "arise"
    local file = ("https://raw.githubusercontent.com/%*/%*/refs/heads/main/%*"):format(user, repo, file)
    return loadstring(game:HttpGet(file))()
end

get_github_file("main.lua")
