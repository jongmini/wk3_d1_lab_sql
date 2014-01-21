require 'pry' 
require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def dbname
  "wk3d1_lab"
end

def with_db
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  yield c
  c.close
end

get '/' do

  erb :index
end

# The Products machinery:

# Get the index of products
get '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products table.
  @products = c.exec_params("SELECT * FROM products;")
  c.close
  erb :products
end

# Get the form for creating a new product
get '/products/new' do
  erb :new_product
end

# POST to create a new product
post '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO products (name, price, description) VALUES ($1,$2,$3)",
                  [params["name"], params["price"], params["description"]])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_product_id = c.exec_params("SELECT currval('products_id_seq');").first["currval"]
  c.close
  redirect "/products/#{new_product_id}"
end

# Update a product
post '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  if [params["cat_name"]].empty?
    # Update the product.
    c.exec_params("UPDATE products SET (name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                  [params["id"], params["name"], params["price"], params["description"]])

  else 
    c.exec_params("UPDATE products SET (name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                  [params["id"], params["name"], params["price"], params["description"]])

    category_id = c.exec_params("SELECT categories.id FROM categories WHERE categories.name = $1", [params["cat_name"]]).first

    # SELECT categories.id FROM categories WHERE categories.name = 'Home'; I DONT UNDERSTAND THE $1, $2 and params syntax!!!

    c.exec_params("INSERT INTO product_category (prod_id, cat_id) = ($1, $2)", [params["id"], params[category_id]])
  end

  c.close
  redirect "/products/#{params["id"]}"
end

get '/products/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1", [params["id"]]).first
 

  c.close


  erb :edit_product
end



# DELETE to delete a product
post '/products/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM products WHERE products.id = $1", [params["id"]])
  c.close
  redirect '/products'
end





# GET the show page for a particular product
get '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1;", [params[:id]]).first    ###

  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products_category table.
  prod_cat = c.exec_params("SELECT cat_id FROM product_category WHERE prod_id = $1;", [params["id"]])
  
  @category = prod_cat.map do |x|
    c.exec_params("SELECT categories.name FROM categories WHERE categories.id = #{x["cat_id"]};").values.flatten
  end

  if @category == nil
    @category = ["none"]

  end
  
  c.close

  erb :product
end

# GET the show page for a particular category
get '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category = c.exec_params("SELECT * FROM categories WHERE categories.id = $1;", [params[:id]]).first

  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products_category table.
  prod_cat = c.exec_params("SELECT prod_id FROM product_category WHERE cat_id = $1;", [params[:id]])

  @product = prod_cat.map do |x|
      c.exec_params("SELECT products.name FROM products WHERE products.id = #{x["prod_id"]};").values.flatten
  end

  if @product.empty?
    @product = ["none"]
  end

  c.close

  erb :category
end

######################################

# The Categories machinery:

# Get the index of categories
get '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the categories table.
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :categories
end

# Get the form for creating a new product
get '/categories/new' do
  erb :new_category
end

# POST to create a new category
post '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the categories table.
  c.exec_params("INSERT INTO categories (name, description) VALUES ($1,$2)",
                  [params["name"], params["description"]])

  # Assuming you created your categories table with "id SERIAL PRIMARY KEY",
  # This will get the id of the category you just created.
  new_category_id = c.exec_params("SELECT currval('categories_id_seq');").first["currval"]
  c.close
  redirect "/categories/#{new_category_id}"
end

# Update a category
post '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Update the category.
  c.exec_params("UPDATE categories SET (name, description) = ($2, $3) WHERE categories.id = $1 ",
                [params["id"], params["name"], params["description"]])
  c.close
  redirect "/categories/#{params["id"]}"
end

get '/categories/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category = c.exec_params("SELECT * FROM categories WHERE categories.id = $1", [params["id"]]).first
  c.close
  erb :edit_category
end


# DELETE to delete a category
post '/categories/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM categories WHERE categories.id = $1", [params["id"]])
  c.close
  redirect '/categories'
end



######################################

def create_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
  CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    price decimal,
    description text
  );
  }
  c.close
end

def create_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
  CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    description text
  );
  }
  c.close
end

def drop_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec "DROP TABLE products;"
  c.close
end

def seed_products_table
  products = [["Laser", "325", "Good for lasering."],
              ["Shoe", "23.4", "Just the left one."],
              ["Wicker Monkey", "78.99", "It has a little wicker monkey baby."],
              ["Whiteboard", "125", "Can be written on."],
              ["Chalkboard", "100", "Can be written on.  Smells like education."],
              ["Podium", "70", "All the pieces swivel separately."],
              ["Bike", "150", "Good for biking from place to place."],
              ["Kettle", "39.99", "Good for boiling."],
              ["Toaster", "20.00", "Toasts your enemies!"],
             ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  products.each do |p|
    c.exec_params("INSERT INTO products (name, price, description) VALUES ($1, $2, $3);", p)
  end
  c.close
end

def seed_categories_table
  categories = [["Clothing", "You wear it."],
              ["Books", "Read a good book."],
              ["Movies", "I love good movies."],
              ["Electronics", "Make sure to charge it."],
              ["Grocery", "Me so hungry."],
              ["Health", "Stay fit!"],
              ["Home", "Where the heart is."],
              ["Accessories", "Other stuff I own."],
              ["Office Products", "Let's get to work!"],
              ["Beauty", "Gotta look good."],
              ["Travel Accessories", "Let's get outta here."],
             ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  categories.each do |p|
    c.exec_params("INSERT INTO categories (name, description) VALUES ($1, $2);", p)
  end
  c.close
end
