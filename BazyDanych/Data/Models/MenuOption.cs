using BlazorBootstrap;

namespace BazyDanych.Data.Models;

public record MenuOption(string Name, string Route, ButtonColor ButtonColor = ButtonColor.Primary)
{
    public static MenuOption Empty { get; } = new("", "");
}