using System.Linq.Expressions;
using BazyDanych.Data;

namespace BazyDanych.Repositories;

public abstract class RepositoryBase<T> : IRepository<T> where T : class
{
    private readonly DapperContext _context;

    public RepositoryBase(DapperContext context)
    {
        _context = context;
    }
    
    public IQueryable<T> FindAll()
    {
        throw new NotImplementedException();
    }

    public IQueryable<T> Find(Expression<Func<T, bool>> expression)
    {
        throw new NotImplementedException();
    }

    public Task CreateAsync(T entity)
    {
        throw new NotImplementedException();
    }

    public Task UpdateAsync(T entity)
    {
        throw new NotImplementedException();
    }

    public Task DeleteAsync(T entity)
    {
        throw new NotImplementedException();
    }
}