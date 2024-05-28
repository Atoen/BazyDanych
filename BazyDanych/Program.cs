using BazyDanych.Components;
using BazyDanych.Data;
using BazyDanych.Data.Models;
using BazyDanych.Repositories;
using BazyDanych.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddControllers();
builder.Services.AddBlazorBootstrap();
builder.Services.AddSingleton<DapperContext>();
builder.Services.AddScoped<ProductRepository>();
builder.Services.AddScoped<EmployeeRepository>();
builder.Services.AddScoped<ClientOrderRepository>();
builder.Services.AddScoped<WarehouseOrderRepository>();
builder.Services.AddScoped<UserService>();
builder.Services.AddScoped<MenuOptionsProvider>();
builder.Services.AddScoped<RedirectManager>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
}

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.MapControllers();

app.Run();
