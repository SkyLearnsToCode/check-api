class ConvertSubdomainsToDowncase < ActiveRecord::Migration
  def change
    Team.all.each do |t|
      unless t.subdomain.match(/[A-Z]/).nil?
        t.subdomain = t.subdomain.downcase
        t.save!
        puts "Updating subdomain for #{t.name}"
      end
    end
  end
end
