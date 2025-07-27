defmodule PhoenixKit.RepoHelper do
  @moduledoc """
  Helper for dynamically resolving the repository to use.
  
  This module provides functions to get the appropriate repository
  based on configuration. It will use the configured repo from
  the parent application if available, otherwise fall back to
  the built-in PhoenixKit.Repo for development/testing.
  """

  @doc """
  Gets the repository module to use.
  
  Expects repo to be configured via Application.get_env(:phoenix_kit, :repo).
  Raises an error if no repo is configured.
  """
  def repo do
    case Application.get_env(:phoenix_kit, :repo) do
      nil -> 
        raise """
        No repository configured for PhoenixKit.
        
        Please configure a repository in your application:
        
            config :phoenix_kit, repo: MyApp.Repo
        """
      repo when is_atom(repo) -> 
        repo
    end
  end

  @doc """
  Delegates to the configured repo's get_by function.
  """
  def get_by(queryable, clauses, opts \\ []) do
    repo().get_by(queryable, clauses, opts)
  end

  @doc """
  Delegates to the configured repo's get function.
  """
  def get(queryable, id, opts \\ []) do
    repo().get(queryable, id, opts)
  end

  @doc """
  Delegates to the configured repo's get! function.
  """
  def get!(queryable, id, opts \\ []) do
    repo().get!(queryable, id, opts)
  end

  @doc """
  Delegates to the configured repo's all function.
  """
  def all(queryable, opts \\ []) do
    repo().all(queryable, opts)
  end

  @doc """
  Delegates to the configured repo's one function.
  """
  def one(queryable, opts \\ []) do
    repo().one(queryable, opts)
  end

  @doc """
  Delegates to the configured repo's insert function.
  """
  def insert(struct_or_changeset, opts \\ []) do
    repo().insert(struct_or_changeset, opts)
  end

  @doc """
  Delegates to the configured repo's insert! function.
  """
  def insert!(struct_or_changeset, opts \\ []) do
    repo().insert!(struct_or_changeset, opts)
  end

  @doc """
  Delegates to the configured repo's update function.
  """
  def update(changeset, opts \\ []) do
    repo().update(changeset, opts)
  end

  @doc """
  Delegates to the configured repo's delete function.
  """
  def delete(struct_or_changeset, opts \\ []) do
    repo().delete(struct_or_changeset, opts)
  end

  @doc """
  Delegates to the configured repo's delete_all function.
  """
  def delete_all(queryable, opts \\ []) do
    repo().delete_all(queryable, opts)
  end

  @doc """
  Delegates to the configured repo's exists? function.
  """
  def exists?(queryable, opts \\ []) do
    repo().exists?(queryable, opts)
  end

  @doc """
  Delegates to the configured repo's query function.
  """
  def query(sql, params \\ [], opts \\ []) do
    repo().query(sql, params, opts)
  end

  @doc """
  Delegates to the configured repo's query! function.
  """
  def query!(sql, params \\ [], opts \\ []) do
    repo().query!(sql, params, opts)
  end

  @doc """
  Delegates to the configured repo's transaction function.
  """
  def transaction(fun_or_multi, opts \\ []) do
    repo().transaction(fun_or_multi, opts)
  end
end