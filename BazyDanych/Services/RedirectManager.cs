using Microsoft.AspNetCore.Components;

namespace BazyDanych.Services;

public class RedirectManager(NavigationManager navigationManager)
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
        navigationManager.NavigateTo("/Login", forceLoad: true);
    }
}