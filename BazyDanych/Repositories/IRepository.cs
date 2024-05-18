using System.Linq.Expressions;

namespace BazyDanych.Repositories;

public interface IRepository<T>
{
    IQueryable<T> FindAll();
    IQueryable<T> Find(Expression<Func<T, bool>> expression);
    
    Task CreateAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(T entity);
}