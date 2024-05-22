using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;

namespace BazyDanych.Services;

public class RedirectManager(NavigationManager navigationManager, IJSRuntime jsRuntime)
{
    public void RedirectTo(string? uri)
    {
        uri ??= string.Empty;
        
        if (!Uri.IsWellFormedUriString(uri, UriKind.Relative))
        {
            uri = navigationManager.ToBaseRelativePath(uri);
        }
        
        navigationManager.NavigateTo(uri);
    }

    public void RedirectToLogin()
    {
        navigationManager.NavigateTo("/Login", true);
    }
    
    public void RedirectToRoot()
    {
        navigationManager.NavigateTo("/");
    }

    public Task GoBackAsync()
    {
        return jsRuntime.InvokeVoidAsync("history.back").AsTask();
    }
}