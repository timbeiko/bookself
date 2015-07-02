class User <ActiveRecord::Base
  include Slugable
  slugable_column :first_name
  
  has_many :user_books
  has_many :books, through: :user_books

  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower


  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.email = auth.info.email
      user.image = auth.info.image + "?type=large"
      user.token = auth.credentials.token
      user.expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end

  # Follows a user.
  def follow(other_user)
    active_relationships.create(followed_id: other_user.id)
  end

  # Unfollows a user.
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # Returns true if the current user is following the other user.
  def following?(other_user)
    following.include?(other_user)
  end

  def self.search(search)
    if search == ""
    elsif search
      key = "%#{search}%"
      where('first_name LIKE :search OR last_name LIKE :search', search: key)
    else
    end
  end

  def same_books(user)
    current_user_books = self.books.uniq
    user_books         = user.books.uniq
    same_books = current_user_books & user_books
  end

  def number_of_same_books(user)
    current_user_books = self.books.uniq
    user_books         = user.books.uniq
    different_books    = (current_user_books - user_books).count
    if different_books < 0
      different_books =  different_books*-1
    end 
    same_books_total = current_user_books.count - different_books
    return same_books_total
  end

  
end